(function () {
  var STORAGE_KEY = 'salanga_webauthn_cred';
  window.salangaBiometricLastError = '';

  function isIos() {
    var ua = window.navigator.userAgent || '';
    var iPhone = /iPad|iPhone|iPod/.test(ua);
    var iPadOs = ua.indexOf('Mac') !== -1 && window.navigator.maxTouchPoints > 1;
    return (iPhone || iPadOs) && !window.MSStream;
  }

  function bufToB64(buf) {
    var bytes = new Uint8Array(buf);
    var bin = '';
    for (var i = 0; i < bytes.length; i++) {
      bin += String.fromCharCode(bytes[i]);
    }
    return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
  }

  function b64ToBuf(b64) {
    b64 = (b64 || '').replace(/-/g, '+').replace(/_/g, '/');
    while (b64.length % 4) b64 += '=';
    var bin = atob(b64);
    var out = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) {
      out[i] = bin.charCodeAt(i);
    }
    return out.buffer;
  }

  function randomBytes(n) {
    var bytes = new Uint8Array(n);
    window.crypto.getRandomValues(bytes);
    return bytes;
  }

  function setError(err) {
    var message = '';
    if (!err) {
      message = 'unknown';
    } else if (typeof err === 'string') {
      message = err;
    } else if (err.message) {
      message = err.name ? err.name + ': ' + err.message : err.message;
    } else {
      message = String(err);
    }
    window.salangaBiometricLastError = message;
  }

  function removeOverlay() {
    var el = document.getElementById('salanga-bio-overlay');
    if (el && el.parentNode) {
      el.parentNode.removeChild(el);
    }
  }

  function showOverlay(onConfirm, onCancel) {
    removeOverlay();
    var overlay = document.createElement('div');
    overlay.id = 'salanga-bio-overlay';
    overlay.setAttribute('style',
      'position:fixed;inset:0;z-index:2147483647;background:rgba(32,16,20,0.45);' +
      'display:flex;align-items:center;justify-content:center;padding:24px;font-family:-apple-system,sans-serif;'
    );
    var card = document.createElement('div');
    card.setAttribute('style',
      'background:#fff8ef;max-width:360px;width:100%;border-radius:16px;padding:24px 20px 16px;' +
      'box-shadow:0 12px 40px rgba(0,0,0,0.25);text-align:center;'
    );
    var title = document.createElement('div');
    title.textContent = 'Вход по Face ID';
    title.setAttribute('style', 'font-size:20px;font-weight:600;color:#3a2a2e;margin-bottom:8px;');
    var text = document.createElement('div');
    text.textContent = 'Нажмите кнопку — Safari запросит Face ID или код устройства.';
    text.setAttribute('style', 'font-size:15px;line-height:1.4;color:#5c4b50;margin-bottom:20px;');
    var confirm = document.createElement('button');
    confirm.type = 'button';
    confirm.textContent = 'Продолжить';
    confirm.setAttribute('style',
      'width:100%;border:0;border-radius:10px;padding:14px 16px;background:#7A0030;color:#fff;' +
      'font-size:16px;font-weight:600;margin-bottom:8px;'
    );
    var cancel = document.createElement('button');
    cancel.type = 'button';
    cancel.textContent = 'Отмена';
    cancel.setAttribute('style',
      'width:100%;border:0;background:transparent;color:#7A0030;font-size:15px;padding:10px;'
    );
    confirm.addEventListener('click', function () {
      removeOverlay();
      onConfirm();
    });
    cancel.addEventListener('click', function () {
      removeOverlay();
      onCancel();
    });
    card.appendChild(title);
    card.appendChild(text);
    card.appendChild(confirm);
    card.appendChild(cancel);
    overlay.appendChild(card);
    document.body.appendChild(overlay);
  }

  async function runWebAuthn() {
    window.salangaBiometricLastError = '';
    if (!navigator.credentials || !window.PublicKeyCredential) {
      setError('WebAuthn недоступен в этом Safari');
      return false;
    }
    var existing = null;
    try {
      existing = window.localStorage.getItem(STORAGE_KEY);
    } catch (e) {}

    try {
      if (existing) {
        var assertion = await navigator.credentials.get({
          publicKey: {
            challenge: randomBytes(32),
            timeout: 120000,
            userVerification: 'required',
            rpId: window.location.hostname,
            allowCredentials: [{
              type: 'public-key',
              id: b64ToBuf(existing)
            }]
          }
        });
        return !!assertion;
      }

      var cred = await navigator.credentials.create({
        publicKey: {
          challenge: randomBytes(32),
          rp: {
            name: 'Горная Саланга',
            id: window.location.hostname
          },
          user: {
            id: randomBytes(16),
            name: 'salanga-guest',
            displayName: 'Горная Саланга'
          },
          pubKeyCredParams: [
            { type: 'public-key', alg: -7 },
            { type: 'public-key', alg: -257 }
          ],
          timeout: 120000,
          attestation: 'none',
          authenticatorSelection: {
            authenticatorAttachment: 'platform',
            userVerification: 'required'
          }
        }
      });
      if (!cred || !cred.rawId) {
        setError('Safari не вернул ключ Face ID');
        return false;
      }
      window.localStorage.setItem(STORAGE_KEY, bufToB64(cred.rawId));
      return true;
    } catch (e) {
      setError(e);
      return false;
    }
  }

  window.salangaBiometricAvailable = async function () {
    if (isIos()) {
      return true;
    }
    if (!window.PublicKeyCredential || !navigator.credentials) {
      return false;
    }
    try {
      return await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
    } catch (e) {
      return false;
    }
  };

  window.salangaBiometricClear = function () {
    try {
      window.localStorage.removeItem(STORAGE_KEY);
    } catch (e) {}
  };

  window.salangaBiometricLastErrorText = function () {
    return window.salangaBiometricLastError || '';
  };

  window.salangaBiometricAuthenticate = function () {
    return new Promise(function (resolve) {
      showOverlay(function () {
        runWebAuthn().then(resolve, function (err) {
          setError(err);
          resolve(false);
        });
      }, function () {
        setError('cancelled');
        resolve(false);
      });
    });
  };
})();
