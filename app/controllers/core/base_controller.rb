module Core
  # Base das telas de administração: exige acesso ao módulo Core.
  class BaseController < ApplicationController
    include Core::ExigeModulo

    modulo :core
  end
end
