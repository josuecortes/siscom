module ApplicationHelper
  def toastr_flash
    flash.each_with_object([]) do |(type, message), flash_messages|
      type = 'success' if type == 'notice'
      type = 'error' if type == 'alert'
      text = "
        <script>
          window.addEventListener('DOMContentLoaded', function(){
            toastr.#{type}('#{message}')
          });
        </script>
      "
      flash_messages << text.html_safe if message
    end.join("\n").html_safe
  end

  def has_error(resource, field)
    resource.errors.messages[field].present? ? "<span class='help-block text-danger'>#{resource.errors.messages[field].join(', ')}</span>".html_safe : nil
  end

  def preencher_dia(tipo)
    if tipo == 'urgente'
      "#{Time.now.strftime('%d/%m/%Y')}"
    else
      dia_util = pegar_dia_util(Time.now + 1.day)
      "#{dia_util.strftime('%d/%m/%Y')}"
    end
  end

  def pegar_dia_util(data)
    if data.wday == 0 or data.wday == 6
      pegar_dia_util(data + 1.day)
    else
      return data
    end
  end

end

