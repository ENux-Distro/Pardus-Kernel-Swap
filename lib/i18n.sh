#!/usr/bin/env bash
#
# i18n.sh - Minimal localization layer for Pardus Kernel Swap.
#
# Language is chosen automatically from the locale (Turkish when the active
# locale starts with "tr", English otherwise). Every user-facing string is a
# printf-style format looked up by key via t(); English is the fallback for any
# key missing a translation, so the app is never left blank.

[ -n "${PKS_I18N_SOURCED:-}" ] && return 0
PKS_I18N_SOURCED=1

declare -gA MSG_EN MSG_TR
PKS_LANG="${PKS_LANG:-en}"

# i18n_init - pick the UI language from the environment locale. Honour an
# explicit PKS_LANG override (en|tr) if the caller set one.
i18n_init() {
    case "${PKS_LANG_OVERRIDE:-}" in
        en|tr) PKS_LANG="$PKS_LANG_OVERRIDE"; return 0 ;;
    esac
    local loc="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
    case "$loc" in
        tr_*|tr|TR_*|TR) PKS_LANG="tr" ;;
        *)               PKS_LANG="en" ;;
    esac
}

# t KEY [args...] - print the localized, formatted string for KEY.
t() {
    local key="$1"; shift
    local fmt=""
    [ "$PKS_LANG" = "tr" ] && fmt="${MSG_TR[$key]-}"
    [ -z "$fmt" ] && fmt="${MSG_EN[$key]-$key}"
    # shellcheck disable=SC2059
    printf "$fmt" "$@"
}

# ----------------------------------------------------------------------------
# English catalog (also the fallback)
# ----------------------------------------------------------------------------
MSG_EN[reboot_reminder]='A new kernel was installed.\n\nA reboot is required for it to take effect.\n\nThis tool will NOT reboot for you. Reboot manually when ready:\n\n    sudo reboot'
MSG_EN[status_known_msg]='Current Kernel:\n%s\n\nSecurity Status:\nKnown CVEs detected\n\n%s\nRecommendation:\nUpgrade to a newer supported kernel.'
MSG_EN[status_clean_msg]='Current Kernel:\n%s\n\nSecurity Status:\nNo known CVEs detected'
MSG_EN[status_unknown_msg]='Current Kernel:\n%s\n\nSecurity Status:\nUnknown - CVE database unavailable.'
MSG_EN[installing_header]='=== %s: installing kernel ==='
MSG_EN[err_unknown_id]="Internal error: unknown kernel id '%s'."
MSG_EN[confirm_install]='Kernel: %s\n\nCurrent Kernel: %s\nNew Kernel:     %s\n\nThis operation will modify the system.\n\nContinue?'
MSG_EN[cancelled_no_changes]='Installation cancelled. No changes were made.'
MSG_EN[dl_image_gauge]='Downloading image: %s ...'
MSG_EN[dl_headers_gauge]='Downloading headers: %s ...'
MSG_EN[dl_failed_msg]='Download failed.\n\nURL:\n%s\n\nThe kernel was not installed. Check your network connection and try again.'
MSG_EN[dl_headers_failed_msg]='Header package download failed.\n\nURL:\n%s\n\nThe kernel image was downloaded but headers are missing. Headers are needed for DKMS and out-of-tree modules. Nothing was installed. Try again.'
MSG_EN[install_ok_msg]='Kernel installed successfully:\n\n%s\n\nA reboot is required (you will be reminded on exit).'
MSG_EN[install_failed_msg]='Installation failed. The system was not modified by a successful install.\nReview the log above and at %s.'
MSG_EN[title_install_failed]='%s - Installation Failed'
MSG_EN[custom_url_prompt]='Enter kernel source archive URL:'
MSG_EN[no_url_cancelled]='No URL provided. Cancelled.'
MSG_EN[confirm_build]='Custom Kernel Build\n\nSource: %s\nCurrent Kernel: %s\n\nThis will download, configure and compile a kernel using:\n  make bindeb-pkg LOCALVERSION="%s"\n\nCompilation can take a long time. Continue?'
MSG_EN[build_starting_msg]='The build is starting and will run in this terminal.\n\nBuild output is written to:\n%s\n\nPress OK to begin. This may take a while.'
MSG_EN[build_header]='=== %s: building custom kernel ==='
MSG_EN[build_source_line]='Source: %s'
MSG_EN[build_log_line]='Log:    %s'
MSG_EN[build_failed_msg]='Custom kernel build failed.\n\nFull log: %s\nNo packages were installed.'
MSG_EN[title_build_failed]='%s - Build Failed'
MSG_EN[confirm_install_built]='Build succeeded. The following packages were produced:\n\n%s\n\nCurrent Kernel: %s\n\nInstall them now?'
MSG_EN[built_not_installed]='Packages built but not installed.\nThey remain in: %s'
MSG_EN[custom_install_ok]='Custom kernel installed successfully.\n\nA reboot is required (you will be reminded on exit).'
MSG_EN[custom_install_failed]='Custom kernel installation failed.\nReview %s for details.'
MSG_EN[menu_prompt]='Select a kernel to install, or Quit.'
MSG_EN[post_install_prompt]='The kernel was installed successfully.\n\nWhat would you like to do?'
# Buttons
MSG_EN[btn_install]='Install'
MSG_EN[btn_cancel]='Cancel'
MSG_EN[btn_build]='Build'
MSG_EN[btn_select]='Select'
MSG_EN[btn_quit]='Quit'
MSG_EN[btn_return_menu]='Return to Menu'
MSG_EN[btn_exit]='Exit'
# CVE layer
MSG_EN[cve_clean]='No known CVEs detected.'
MSG_EN[cve_db_unavail]='CVE database unavailable - security status unknown.'
MSG_EN[cve_recommend_label]='Recommendation'
# Kernel catalog
MSG_EN[adv_label]='Advantages:'
MSG_EN[disadv_label]='Disadvantages:'
MSG_EN[custom_menu_label]='Custom  (user-provided kernel source)'
MSG_EN[custom_desc]='Custom\n\nUser compiles their own kernel source.\n\nAdvantages:\n  * complete control\n\nDisadvantages:\n  * compilation time\n  * advanced knowledge required\n'

# ----------------------------------------------------------------------------
# Turkish catalog
# ----------------------------------------------------------------------------
MSG_TR[reboot_reminder]='Yeni bir çekirdek kuruldu.\n\nEtkinleşmesi için sistemi yeniden başlatmanız gerekir.\n\nBu araç sizin yerinize yeniden başlatma YAPMAZ. Hazır olduğunuzda elle başlatın:\n\n    sudo reboot'
MSG_TR[status_known_msg]='Geçerli Çekirdek:\n%s\n\nGüvenlik Durumu:\nBilinen CVE'\''ler tespit edildi\n\n%s\nÖneri:\nDesteklenen daha yeni bir çekirdeğe yükseltin.'
MSG_TR[status_clean_msg]='Geçerli Çekirdek:\n%s\n\nGüvenlik Durumu:\nBilinen bir CVE tespit edilmedi'
MSG_TR[status_unknown_msg]='Geçerli Çekirdek:\n%s\n\nGüvenlik Durumu:\nBilinmiyor - CVE veritabanına ulaşılamıyor.'
MSG_TR[installing_header]='=== %s: çekirdek kuruluyor ==='
MSG_TR[err_unknown_id]="İç hata: bilinmeyen çekirdek kimliği '%s'."
MSG_TR[confirm_install]='Çekirdek: %s\n\nGeçerli Çekirdek: %s\nYeni Çekirdek:    %s\n\nBu işlem sistemi değiştirecek.\n\nDevam edilsin mi?'
MSG_TR[cancelled_no_changes]='Kurulum iptal edildi. Hiçbir değişiklik yapılmadı.'
MSG_TR[dl_image_gauge]='Çekirdek imajı indiriliyor: %s ...'
MSG_TR[dl_headers_gauge]='Başlık dosyaları indiriliyor: %s ...'
MSG_TR[dl_failed_msg]='İndirme başarısız.\n\nURL:\n%s\n\nÇekirdek kurulmadı. Ağ bağlantınızı kontrol edip tekrar deneyin.'
MSG_TR[dl_headers_failed_msg]='Başlık paketi indirilemedi.\n\nURL:\n%s\n\nÇekirdek imajı indirildi ancak başlık dosyaları eksik. Başlıklar DKMS ve harici modüller için gereklidir. Hiçbir şey kurulmadı. Tekrar deneyin.'
MSG_TR[install_ok_msg]='Çekirdek başarıyla kuruldu:\n\n%s\n\nYeniden başlatma gerekiyor (çıkışta hatırlatılacak).'
MSG_TR[install_failed_msg]='Kurulum başarısız. Sistem değiştirilmedi.\nYukarıdaki günlüğü ve %s dosyasını inceleyin.'
MSG_TR[title_install_failed]='%s - Kurulum Başarısız'
MSG_TR[custom_url_prompt]='Çekirdek kaynak arşivi URL'\''sini girin:'
MSG_TR[no_url_cancelled]='URL girilmedi. İptal edildi.'
MSG_TR[confirm_build]='Özel Çekirdek Derleme\n\nKaynak: %s\nGeçerli Çekirdek: %s\n\nŞu komutla bir çekirdek indirilecek, yapılandırılacak ve derlenecek:\n  make bindeb-pkg LOCALVERSION="%s"\n\nDerleme uzun sürebilir. Devam edilsin mi?'
MSG_TR[build_starting_msg]='Derleme başlıyor ve bu terminalde çalışacak.\n\nDerleme çıktısı şuraya yazılıyor:\n%s\n\nBaşlamak için Tamam'\''a basın. Bu işlem biraz sürebilir.'
MSG_TR[build_header]='=== %s: özel çekirdek derleniyor ==='
MSG_TR[build_source_line]='Kaynak: %s'
MSG_TR[build_log_line]='Günlük: %s'
MSG_TR[build_failed_msg]='Özel çekirdek derlemesi başarısız.\n\nTam günlük: %s\nHiçbir paket kurulmadı.'
MSG_TR[title_build_failed]='%s - Derleme Başarısız'
MSG_TR[confirm_install_built]='Derleme başarılı. Şu paketler üretildi:\n\n%s\n\nGeçerli Çekirdek: %s\n\nŞimdi kurulsun mu?'
MSG_TR[built_not_installed]='Paketler derlendi ancak kurulmadı.\nŞurada duruyor: %s'
MSG_TR[custom_install_ok]='Özel çekirdek başarıyla kuruldu.\n\nYeniden başlatma gerekiyor (çıkışta hatırlatılacak).'
MSG_TR[custom_install_failed]='Özel çekirdek kurulumu başarısız.\nAyrıntılar için %s dosyasını inceleyin.'
MSG_TR[menu_prompt]='Kurmak için bir çekirdek seçin veya Çıkın.'
MSG_TR[post_install_prompt]='Çekirdek başarıyla kuruldu.\n\nNe yapmak istersiniz?'
# Buttons
MSG_TR[btn_install]='Kur'
MSG_TR[btn_cancel]='İptal'
MSG_TR[btn_build]='Derle'
MSG_TR[btn_select]='Seç'
MSG_TR[btn_quit]='Çık'
MSG_TR[btn_return_menu]='Menüye Dön'
MSG_TR[btn_exit]='Çık'
# CVE layer
MSG_TR[cve_clean]='Bilinen bir CVE tespit edilmedi.'
MSG_TR[cve_db_unavail]='CVE veritabanına ulaşılamıyor - güvenlik durumu bilinmiyor.'
MSG_TR[cve_recommend_label]='Öneri'
# Kernel catalog
MSG_TR[adv_label]='Avantajlar:'
MSG_TR[disadv_label]='Dezavantajlar:'
MSG_TR[custom_menu_label]='Özel  (kullanıcı tarafından sağlanan çekirdek kaynağı)'
MSG_TR[custom_desc]='Özel\n\nKullanıcı kendi çekirdek kaynağını derler.\n\nAvantajlar:\n  * tam denetim\n\nDezavantajlar:\n  * derleme süresi\n  * ileri düzey bilgi gerekir\n'
