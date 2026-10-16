module Core
  # Para o BaseController de cada módulo: sem acesso ativo ao módulo → 403.
  #
  #   class Rh::BaseController < ApplicationController
  #     include Core::ExigeModulo
  #     modulo :rh
  #   end
  module ExigeModulo
    extend ActiveSupport::Concern

    included do
      class_attribute :modulo_exigido, instance_writer: false
      before_action :exigir_modulo!
    end

    class_methods do
      def modulo(chave)
        self.modulo_exigido = chave.to_s
      end
    end

    private

    def exigir_modulo!
      raise "#{self.class.name} não declarou o módulo (modulo :chave)" if modulo_exigido.blank?
      raise Core::AcessoNegado unless autorizacao.acesso?(modulo_exigido)
    end
  end
end
