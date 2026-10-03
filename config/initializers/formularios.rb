# Os formulários desenham o erro por campo (borda vermelha + mensagem), no
# padrão do seed. Sem o invólucro <div class="field_with_errors"> do Rails,
# que quebra o alinhamento dos campos.
Rails.application.config.action_view.field_error_proc = proc { |html, _instancia| html }
