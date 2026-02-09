function playMensagemBeep() {
  try {
    var ctx = new (window.AudioContext || window.webkitAudioContext)();
    var osc = ctx.createOscillator();
    var gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = 880;
    gain.gain.value = 0.05;
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    setTimeout(function() {
      osc.stop();
      ctx.close();
    }, 200);
  } catch (e) {}
}

App.cable.subscriptions.create("MensagensChannel", {
  connected: function() {},
  disconnected: function() {},
  received: function(data) {
    if (!data) return;
    if (data.type === "badge" && window.MensagensUI && window.MensagensUI.updateBadge) {
      var count = data.count || 0;
      window.MensagensUI.updateBadge(String(count));
    }
    if (data.type === "badge" && window.MensagensUI && window.MensagensUI.updateTabBadge) {
      var countTab = data.count || 0;
      window.MensagensUI.updateTabBadge(countTab);
    }
    if (data.type === "mensagem" && data.html) {
      var currentId = window.MensagensUI && window.MensagensUI.currentRequisicaoId;
      if (currentId && String(data.requisicao_id) === String(currentId)) {
        var $targets = $('.conversa, #chat-float-conversa');
        $targets.append(data.html);
        var $scrollTargets = $('.msg_history');
        $scrollTargets.each(function() {
          var $el = $(this);
          $el.scrollTop(this.scrollHeight);
        });
        if (window.MensagensUI && window.MensagensUI.updateConversaBadge) {
          window.MensagensUI.updateConversaBadge(data.requisicao_id, 0);
        }
      }
      if (data.playSound) {
        playMensagemBeep();
      }
    }
    if (data.type === "conversa_badge" && window.MensagensUI && window.MensagensUI.updateConversaBadge) {
      window.MensagensUI.updateConversaBadge(data.requisicao_id, data.count || 0);
    }
    if (data.type === "dropdown" && data.html) {
      $('#mensagens-dropdown-items').html(data.html);
    }
  }
});
