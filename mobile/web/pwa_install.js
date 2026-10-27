(function () {
  let deferredPrompt = null;

  const ua = window.navigator.userAgent || '';
  window.salangaIsIos =
    /iPad|iPhone|iPod/.test(ua) && !window.MSStream;
  window.salangaIsAndroid = /Android/.test(ua);
  function refreshStandalone() {
    window.salangaIsStandalone =
      window.matchMedia('(display-mode: standalone)').matches ||
      window.matchMedia('(display-mode: fullscreen)').matches ||
      window.navigator.standalone === true;
  }
  refreshStandalone();
  window.salangaCanInstall = false;

  function notifyAvailability() {
    window.dispatchEvent(new Event('salanga-install-available'));
  }

  window.addEventListener('beforeinstallprompt', function (event) {
    event.preventDefault();
    deferredPrompt = event;
    window.salangaCanInstall = true;
    notifyAvailability();
  });

  window.salangaPromptInstall = async function () {
    if (!deferredPrompt) {
      return false;
    }
    deferredPrompt.prompt();
    const choice = await deferredPrompt.userChoice;
    deferredPrompt = null;
    window.salangaCanInstall = false;
    notifyAvailability();
    return choice.outcome === 'accepted';
  };

  window.addEventListener('appinstalled', function () {
    deferredPrompt = null;
    window.salangaCanInstall = false;
    refreshStandalone();
    notifyAvailability();
  });

  window.addEventListener('pageshow', refreshStandalone);
  document.addEventListener('visibilitychange', refreshStandalone);
})();
