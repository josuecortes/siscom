module Rh
  # Base das telas do RH: exige acesso ao módulo.
  class BaseController < ApplicationController
    include Core::ExigeModulo

    modulo :rh
  end
end
