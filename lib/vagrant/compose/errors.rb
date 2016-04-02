require "vagrant"

module VagrantPlugins
  module Compose

    #Plugin custom error classes, handling localization of error messages
    module Errors
      #Base class for vagrant compose custom errors
      class VagrantComposeError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_compose.errors")
      end

      class ClusterInitializeError < VagrantComposeError
        error_key(:initialize_error)
      end

      class AttributeExpressionError < VagrantComposeError
        error_key(:attribute_expression_error)
      end

      class ContextVarExpressionError < VagrantComposeError
        error_key(:context_var_expression_error)
      end

      class GroupVarExpressionError < VagrantComposeError
        error_key(:group_var_expression_error)
      end

      class HostVarExpressionError < VagrantComposeError
        error_key(:host_var_expression_error)
      end
    end
  end
end