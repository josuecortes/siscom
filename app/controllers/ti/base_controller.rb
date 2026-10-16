module Ti
  # Base das telas da TI: exige acesso ao módulo.
  class BaseController < ApplicationController
    include Core::ExigeModulo

    modulo :ti
  end
end
