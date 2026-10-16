namespace :remaster do
  namespace :transporte do
    desc "Converte os papéis antigos do transporte: req_serv_tp → solicitante, tec_serv_tp → técnico. Idempotente."
    task importar_papeis: :environment do
      relatorio = Core::Api.importar_papeis("req_serv_tp" => [ %w[transporte solicitante] ], "tec_serv_tp" => [ %w[transporte tecnico] ])

      puts "Transporte: #{relatorio}"
    end
  end
end
