;(function() {
  window.MensagensUI = window.MensagensUI || {};

  var baseTitle = document.title;
  var baseIconHref = null;
  var baseIconLoaded = false;
  var baseIconImage = null;
  var pendingCount = null;
  var lastCount = 0;
  var blinkInterval = null;
  var blinkOn = false;

  function ensureFaviconLink() {
    var link = document.querySelector('link[rel~="icon"]');
    if (!link) {
      link = document.createElement('link');
      link.rel = 'icon';
      link.href = '/favicon.ico';
      document.head.appendChild(link);
    }
    return link;
  }

  function loadBaseIcon() {
    var link = ensureFaviconLink();
    baseIconHref = link.getAttribute('data-base-href') || link.href;
    if (!baseIconHref) {
      baseIconLoaded = false;
      return;
    }
    if (!baseIconImage) {
      baseIconImage = new Image();
      baseIconImage.onload = function() {
        baseIconLoaded = true;
        if (pendingCount !== null) {
          renderFavicon(pendingCount);
        }
      };
      baseIconImage.onerror = function() {
        baseIconLoaded = false;
      };
    }
    if (baseIconImage.src !== baseIconHref) {
      baseIconImage.src = baseIconHref;
    }
  }

  function renderFavicon(count) {
    var link = ensureFaviconLink();
    if (!baseIconHref) {
      baseIconHref = link.getAttribute('data-base-href') || link.href;
    }

    if (!count || count <= 0) {
      if (baseIconHref) {
        link.href = baseIconHref;
      }
      return;
    }

    var size = 32;
    var canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    var ctx = canvas.getContext('2d');

    if (baseIconLoaded && baseIconImage) {
      ctx.drawImage(baseIconImage, 0, 0, size, size);
    } else {
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(0, 0, size, size);
    }

    var badgeText = count > 99 ? '99+' : String(count);
    var radius = 9;
    var cx = size - radius;
    var cy = radius;

    ctx.fillStyle = '#1e88e5';
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 10px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(badgeText, cx, cy);

    link.href = canvas.toDataURL('image/png');
  }

  function startBlink() {
    if (blinkInterval) return;
    blinkInterval = setInterval(function() {
      blinkOn = !blinkOn;
      if (blinkOn) {
        document.title = '(' + lastCount + ') ' + baseTitle;
      } else {
        document.title = baseTitle;
      }
    }, 800);
  }

  function stopBlink() {
    if (blinkInterval) {
      clearInterval(blinkInterval);
      blinkInterval = null;
      blinkOn = false;
    }
  }

  window.MensagensUI.updateTabBadge = function(count) {
    var num = parseInt(count, 10) || 0;
    lastCount = num;
    if (num > 0) {
      if (document.hidden) {
        startBlink();
      } else {
        stopBlink();
        document.title = '(' + num + ') ' + baseTitle;
      }
    } else {
      stopBlink();
      document.title = baseTitle;
    }
    pendingCount = num;
    loadBaseIcon();
  };

  document.addEventListener('visibilitychange', function() {
    if (document.hidden) {
      if (lastCount > 0) {
        startBlink();
      }
    } else {
      stopBlink();
      if (lastCount > 0) {
        document.title = '(' + lastCount + ') ' + baseTitle;
      } else {
        document.title = baseTitle;
      }
    }
  });
})();
