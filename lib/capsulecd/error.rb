module CapsuleCD
  # The collection of Minimart specific errors.
  module Error
    class BaseError < StandardError; end

    # Raised when the config file specifies a hook/override for a step when the type is :repo
    class EngineTransformUnavailableStep < BaseError; end

    # Raised when the source is not specified
    class SourceUnspecifiedError < BaseError; end

    # Raised when capsule cannot create an authenticated client for the source.
    class SourceAuthenticationFailed < BaseError; end

    # Raised when there is an error parsing the repo payload format.
    class SourcePayloadFormatError < BaseError; end

    # Raised when a source payload is unsupported/action is invalid
    class SourcePayloadUnsupported < BaseError; end

    # Raised when the user who started the packaging is unauthorized (non-collaborator)
    class SourceUnauthorizedUser < BaseError; end

    # Raised when the package is missing certain required files (ie metadata.rb, package.json, setup.py, etc)
    class BuildPackageInvalid < BaseError; end

    # Raised when the source could not be compiled or build for any reason
    class BuildPackageFailed < BaseError; end

    # Raised when package dependencies fail to install correctly.
    class TestDependenciesError < BaseError; end

    # Raised when the package test runner fails
    class TestRunnerError < BaseError; end

    # Raised when credentials required to upload/deploy new package are missing.
    class ReleaseCredentialsMissing < BaseError; end

    # Raised when an error occurs while uploading package.
    class ReleasePackageError < BaseError; end

  end
end
