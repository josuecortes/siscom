class FillMunicipios < ActiveRecord::Migration[6.0]
  def change
    TransporteEscolar::Municipio.create([ {nome: 'AMAPÁ'},
                                          {nome: 'CALÇOENE'},
                                          {nome: 'CUTIAS'},
                                          {nome: 'FERREIRA GOMES'},
                                          {nome: 'ITAUBAL'},
                                          {nome: 'LARANJAL DO JARI'},
                                          {nome: 'MACAPÁ BAILIQUE'},
                                          {nome: 'MACAPÁ FAZENDINHA'},
                                          {nome: 'MACAPÁ PACUÍ'},
                                          {nome: 'MACAPÁ PEDREIRA'},
                                          {nome: 'MACAPÁ RURAL'},
                                          {nome: 'MACAPÁ URBANA'},  
                                          {nome: 'MAZAGÃO'},
                                          {nome: 'OIAPOQUE'},
                                          {nome: 'PEDRA BRANCA'},
                                          {nome: 'PORTO GRANDE'},
                                          {nome: 'PRACUÚBA'},
                                          {nome: 'SANTANA'},
                                          {nome: 'SERRA DO NAVIO'},
                                          {nome: 'TARTARUGALZINHO'},
                                          {nome: 'VITÓRIA DO JARI'},                                          
                                         ])
  end
end
