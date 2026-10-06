module Equipamentos
  # Base das telas de Equipamentos: exige acesso ao módulo.
  class BaseController < ApplicationController
    include Core::ExigeModulo

    modulo :equipamentos
  end
end
