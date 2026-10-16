module Transporte
  # Base das telas do Transporte: exige acesso ao módulo.
  class BaseController < ApplicationController
    include Core::ExigeModulo

    modulo :transporte
  end
end
