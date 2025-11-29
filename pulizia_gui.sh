
#!/bin/bash
set -euo pipefail

# Script di pulizia sicuro per Ubuntu 24.04 LTS con interfaccia grafica (Zenity)
# Modalità dry-run inclusa
# Avviabile con doppio click

# Variabili globali
DRY_RUN="${DRY_RUN:-false}"
DRY_ESCALATED="${DRY_ESCALATED:-0}"

# Controlla se zenity è installato
if ! command -v zenity &> /dev/null; then
    echo "Zenity non è installato. Installalo con: sudo apt install zenity"
    exit 1
fi

# Se necessario, rilancia con privilegi (pkexec preferito)
if [ "${DRY_ESCALATED}" != "1" ] && [ "$EUID" -ne 0 ]; then
    # Chiedi se l'utente vuole la modalità dry-run prima dell'escalation
    if zenity --question --title="Pulizia Sistema" --text="Vuoi eseguire la pulizia in modalità simulazione (dry-run)?" --ok-label="Sì" --cancel-label="No"; then
        DRY_RUN_CHOICE="true"
    else
        DRY_RUN_CHOICE="false"
    fi

    # Rilancia con privilegi passando la scelta dry-run
    if command -v pkexec &>/dev/null; then
        exec env DRY_ESCALATED=1 DRY_RUN="${DRY_RUN_CHOICE}" pkexec env DISPLAY="${DISPLAY:-}" XAUTHORITY="${XAUTHORITY:-}" bash "$0" "$@"
    else
        exec env DRY_ESCALATED=1 DRY_RUN="${DRY_RUN_CHOICE}" sudo -E bash "$0" "$@"
    fi
fi

# Trap per pulire in caso di interruzione
on_abort() {
    zenity --warning --title="Annullato" --text="Pulizia annullata dall'utente."
    exit 1
}
trap 'on_abort' TERM INT

# File temporaneo per il riepilogo dry-run
DRY_SUMMARY_FILE=$(mktemp)
trap 'rm -f "${DRY_SUMMARY_FILE}"' EXIT

# Percorsi assoluti per i comandi principali
APT_CMD="/usr/bin/apt"
JOURNALCTL_CMD="/usr/bin/journalctl"

# Funzione per aggiungere al riepilogo
add_to_summary() {
    echo "$1" >> "${DRY_SUMMARY_FILE}"
}

# Produzione dei messaggi di progresso
(
echo "0"; sleep 0.2

# 1. Autoremove + purge
if [ "${DRY_RUN}" = "true" ]; then
    REMOVABLE=$("${APT_CMD}" --dry-run autoremove --purge 2>/dev/null | grep -c "^Remv " || echo "0")
    add_to_summary "🔄 [Dry-run] Pacchetti da rimuovere: ${REMOVABLE} (apt autoremove --purge)"
    echo "20"
else
    echo "10"
    "${APT_CMD}" -y autoremove --purge
    echo "20"
fi
sleep 0.1

# 2. Autoclean
if [ "${DRY_RUN}" = "true" ]; then
    add_to_summary "🗑️ [Dry-run] Pulizia dei pacchetti obsoleti (apt autoclean)"
    echo "40"
else
    echo "30"
    "${APT_CMD}" -y autoclean
    echo "40"
fi
sleep 0.1

# 3. Clean
if [ "${DRY_RUN}" = "true" ]; then
    CACHE_SIZE=$(du -sh /var/cache/apt/archives 2>/dev/null | cut -f1 || echo "N/A")
    add_to_summary "🧹 [Dry-run] Cache APT da pulire: ${CACHE_SIZE} (apt clean)"
    echo "60"
else
    echo "50"
    "${APT_CMD}" clean
    echo "60"
fi
sleep 0.1

# 4. Journald
if [ "${DRY_RUN}" = "true" ]; then
    JOURNAL_SIZE=$("${JOURNALCTL_CMD}" --disk-usage 2>/dev/null | grep -oP '\d+\.\d+[GM]' | head -1 || echo "N/A")
    add_to_summary "📜 [Dry-run] Log journald attuali: ${JOURNAL_SIZE}, verranno rimossi quelli oltre 7 giorni"
    echo "80"
else
    echo "70"
    "${JOURNALCTL_CMD}" --vacuum-time=7d || true
    echo "80"
fi
sleep 0.1

# 5. Cache miniature
THUMB_DIR="${HOME}/.cache/thumbnails"
if [ -d "${THUMB_DIR}" ]; then
    if [ "${DRY_RUN}" = "true" ]; then
        NUM_FILES=$(find "${THUMB_DIR}" -type f 2>/dev/null | wc -l)
        THUMB_SIZE=$(du -sh "${THUMB_DIR}" 2>/dev/null | cut -f1 || echo "N/A")
        add_to_summary "🖼️ [Dry-run] Cache miniature: ${NUM_FILES} file (${THUMB_SIZE}) verrebbero rimossi"
        echo "100"
    else
        echo "90"
        find "${THUMB_DIR}" -mindepth 1 -delete 2>/dev/null || true
        echo "100"
    fi
else
    echo "100"
fi
sleep 0.1

) | zenity --progress \
           --title="Pulizia Sistema" \
           --text="Pulizia in corso..." \
           --percentage=0 \
           --auto-close

# Salva lo stato della pipe immediatamente
PIPE_STATUS=("${PIPESTATUS[@]}")

# Controlla se zenity è stato annullato (indice 1 della pipe)
if [ "${PIPE_STATUS[1]:-0}" -ne 0 ]; then
    zenity --warning --title="Annullato" --text="Pulizia annullata dall'utente."
    exit 1
fi

# Fine: mostra riepilogo per dry-run o conferma
if [ "${DRY_RUN}" = "true" ]; then
    if [ ! -s "${DRY_SUMMARY_FILE}" ]; then
        zenity --info --title="Dry-run completato" --text="Nessuna azione da simulare."
    else
        zenity --text-info --title="Dry-run - Azioni simulate" --filename="${DRY_SUMMARY_FILE}" --width=600 --height=400
    fi
else
    zenity --info --title="Pulizia completata" --text="✅ Pulizia del sistema completata!"
fi
# ...existing code...
