require 'spec_helper'
require 'capsulecd/base/source/github'

describe CapsuleCD::Source::Github do
  describe '#source_configure' do

    describe 'when no authentication token is present' do
      let(:test_engine) { Class.new { include CapsuleCD::Source::Github } }
      let(:config) { CapsuleCD::Configuration.new({}) }
      it 'should raise an error' do
        engine = test_engine.new
        engine.instance_variable_set(:@config, config)
        expect { engine.source_configure }.to raise_error(CapsuleCD::Error::SourceAuthenticationFailed)
      end
    end

    describe 'when authentication token is present' do
      let(:test_engine) { Class.new { include CapsuleCD::Source::Github } }
      let(:config) { CapsuleCD::Configuration.new({:config_file => 'spec/fixtures/sample_configuration.yml'}) }

      it 'should successfully create an source_client' do
        allow(Dir).to receive(:mktmpdir).and_return('/tmp')
        engine = test_engine.new
        engine.instance_variable_set(:@config, config)
        engine.source_configure
        expect(engine.source_client).to be_a_kind_of Octokit::Client
      end
    end
  end

  describe '#source_process_push_payload' do
    let(:test_engine) { Class.new { include CapsuleCD::Source::Github } }
    let(:payload) do
      {
        'head' => {
          'sha' => '0a5948802a2bba02e019fd13bf3db3c5329faae6',
          'ref' => 'master',
          'repo' => {
            'clone_url' => 'https://github.com/AnalogJ/npm_analogj_test.git',
            'name' => 'npm_analog_test'
          }
        }
      }
    end
    let(:config) { CapsuleCD::Configuration.new({:config_file => 'spec/fixtures/sample_configuration.yml'}) }
    it 'should clone git repo' do
      engine = test_engine.new
      engine.instance_variable_set(:@config, config)
      engine.instance_variable_set(:@source_git_parent_path, '/tmp')
      allow(CapsuleCD::GitUtils).to receive(:clone).and_return(engine.source_git_parent_path + payload['head']['repo']['name'])
      allow(CapsuleCD::GitUtils).to receive(:checkout).and_return(true)

      engine.source_process_push_payload(payload)

      expect(engine.source_git_local_path).to eql(engine.source_git_parent_path + payload['head']['repo']['name'])
      expect(engine.source_git_local_branch).to eql(payload['head']['repo']['branch'])
      expect(engine.source_git_head_info).to be_a(Hash)
    end

    describe 'with an invalid payload' do
      it 'should raise an error' do
        engine = test_engine.new
        engine.instance_variable_set(:@config, config)
        engine.instance_variable_set(:@source_git_parent_path, '/tmp')
        expect { engine.source_process_push_payload('head' => {}) }.to raise_error(CapsuleCD::Error::SourcePayloadFormatError)
      end
    end
  end

  describe '#source_process_pull_request_payload' do
    let(:test_engine) { Class.new { include CapsuleCD::Source::Github } }
    let(:source_client_double) { instance_double(Octokit::Client) }
    let(:config) { CapsuleCD::Configuration.new({:config_file => 'spec/fixtures/sample_configuration.yml'}) }

    describe 'with a closed pull request payload' do
      let(:payload) do
        {
          'state' => 'closed'
        }
      end
      it 'should raise an error' do
        engine = test_engine.new
        engine.instance_variable_set(:@config, config)
        expect { engine.source_process_pull_request_payload(payload) }.to raise_error(CapsuleCD::Error::SourcePayloadUnsupported)
      end
    end

    describe 'when the default branch is not the same as the pull request base branch' do
      let(:config) { CapsuleCD::Configuration.new({:config_file => 'spec/fixtures/sample_configuration.yml'}) }
      let(:payload) do
        {
          'state' => 'open',
          'base' => {
            'repo' => {
              'default_branch' => 'master'
            },
            'ref' => 'development'
          }
        }
      end
      it 'should raise an error' do
        engine = test_engine.new
        engine.instance_variable_set(:@config, config)
        expect { engine.source_process_pull_request_payload(payload) }.to raise_error(CapsuleCD::Error::SourcePayloadUnsupported)
      end
    end

    describe 'when the user who opened the PR is not a collaborator' do
      let(:payload) do
        {
          'state' => 'open',
          'number' => 8,
          'base' => {
            'repo' => {
              'full_name' => 'AnalogJ/npm_analogj_test',
              'default_branch' => 'master',
              'clone_url' => 'https://github.com/AnalogJ/npm_analogj_test.git',
              'name' => 'npm_analog_test'
            },
            'sha' => '0a5948802a2bba02e019fd13bf3db3c5329faae6',
            'ref' => 'master'
          },
          'user' => {
            'login' => 'AnalogJ'
          }
        }
      end

      it 'should raise an error', :skip => true do
        engine = test_engine.new
        engine.instance_variable_set(:@source_client, source_client_double)
        engine.instance_variable_set(:@source_git_parent_path, '/tmp')

        allow(source_client_double).to receive(:collaborator?).and_return(false)
        allow(source_client_double).to receive(:add_comment).and_return(false)

        expect { engine.source_process_pull_request_payload(payload) }.to raise_error(CapsuleCD::Error::SourceUnauthorizedUser)
      end
    end

    describe 'when using a valid payload' do
      let(:payload) do
        {
          'state' => 'open',
          'number' => 8,
          'base' => {
            'sha' => '0a5948802a2bba02e019fd13bf3db3c5329faae6',
            'ref' => 'master',
            'repo' => {
              'full_name' => 'AnalogJ/npm_analogj_test',
              'clone_url' => 'https://github.com/AnalogJ/npm_analogj_test.git',
              'name' => 'npm_analog_test',
              'default_branch' => 'master'
            }
          },
          'head' => {
            'sha' => '0a5948802a2bba02e019fd13bf3db3c5329faae6',
            'ref' => 'feature',
            'repo' => {
              'full_name' => 'AnalogJ/npm_analogj_test',
              'clone_url' => 'https://github.com/AnalogJ/npm_analogj_test.git',
              'name' => 'npm_analog_test'
            }
          },
          'user' => {
            'login' => 'AnalogJ'
          }
        }
      end

      it 'should clone merged repo' do
        engine = test_engine.new
        engine.instance_variable_set(:@config, config)
        engine.instance_variable_set(:@source_client, source_client_double)
        engine.instance_variable_set(:@source_git_parent_path, '/tmp')

        allow(source_client_double).to receive(:collaborator?).and_return(true)
        allow(source_client_double).to receive(:add_comment).and_return(false)
        allow(source_client_double).to receive(:create_status).and_return(false)
        allow(CapsuleCD::GitUtils).to receive(:clone).and_return(engine.source_git_parent_path + payload['head']['repo']['name'])
        allow(CapsuleCD::GitUtils).to receive(:fetch).and_return(true)
        allow(CapsuleCD::GitUtils).to receive(:checkout).and_return(true)

        engine.source_process_pull_request_payload(payload)

        expect(engine.source_git_local_branch).to eql('pr_8')
        expect(engine.source_git_local_path).to eql(engine.source_git_parent_path + payload['head']['repo']['name'])
        expect(engine.source_git_head_info).to be_a(Hash)
        expect(engine.source_git_base_info).to be_a(Hash)
      end
    end
  end

  describe '#source_release' do
    let(:test_engine) { Class.new { include CapsuleCD::Source::Github } }
    let(:source_client_double) { instance_double(Octokit::Client) }
    let(:git_commit_double) { instance_double(Git::Object::Commit) }

    describe 'when release state is valid' do
      let(:payload) do
        {
          'state' => 'open',
          'number' => 8,
          'base' => {
            'sha' => '0a5948802a2bba02e019fd13bf3db3c5329faae6',
            'repo' => {
              'full_name' => 'AnalogJ/npm_analogj_test',
              'clone_url' => 'https://github.com/AnalogJ/npm_analogj_test.git',
              'name' => 'npm_analog_test',
              'default_branch' => 'master'
            },
            'ref' => 'master'
          },
          'head' => {
            'sha' => '0a5948802a2bba02e019fd13bf3db3c5329faae6',
            'repo' => {
              'full_name' => 'AnalogJ/npm_analogj_test',
              'clone_url' => 'https://github.com/AnalogJ/npm_analogj_test.git',
              'name' => 'npm_analog_test'
            },
            'ref' => 'feature'
          },
          'user' => {
            'login' => 'AnalogJ'
          }
        }
      end

      it 'should successfully push changes to github' do
        engine = test_engine.new
        engine.instance_variable_set(:@source_client, source_client_double)
        engine.instance_variable_set(:@source_release_commit, git_commit_double)
        engine.instance_variable_set(:@source_git_local_path, '')
        engine.instance_variable_set(:@source_git_local_branch, '')
        engine.instance_variable_set(:@source_git_base_info, payload['base'])
        engine.instance_variable_set(:@source_git_head_info, payload['head'])
        engine.instance_variable_set(:@source_release_artifacts, [])
        engine.instance_variable_set(:@source_git_parent_path, test_directory)

        allow(source_client_double).to receive(:create_release).and_return(true)
        allow(source_client_double).to receive(:upload_asset).and_return(false)
        allow(source_client_double).to receive(:create_status).and_return(false)
        allow(git_commit_double).to receive(:sha).and_return('0a5948802a2bba02e019fd13bf3db3c5329faae6')
        allow(git_commit_double).to receive(:name).and_return('test')
        allow(CapsuleCD::GitUtils).to receive(:push).and_return(true)
        allow(CapsuleCD::GitUtils).to receive(:generate_changelog).and_return('')
        allow(FileUtils).to receive(:remove_entry_secure).and_return(true)

        engine.source_release
      end
    end
  end
end
