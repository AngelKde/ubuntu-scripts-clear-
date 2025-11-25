
#!/bin/bash
# ...existing code...
set -euo pipefail

# Script di pulizia sicuro per Ubuntu 24.04 LTS con interfaccia grafica (Zenity)
# Modalità dry-run inclusa
# Avviabile con doppio click

# evita errori con -u
DRY_RUN="false"
DRY_ESCALATED="${DRY_ESCALATED:-0}"

# Controlla se zenity è installato
if ! command -v zenity &> /dev/null; then
    echo "Zenity non è installato. Installalo con: sudo apt install zenity"
    exit 1
fi

# Se necessario, rilancia con privilegi (pkexec preferito)
if [ "${DRY_ESCALATED}" != "1" ] && [ "$EUID" -ne 0 ]; then
    # Chiedi se l'utente vuole la modalità dry-run prima dell'escalation:
    if zenity --question --title="Pulizia Sistema" --text="Vuoi eseguire la pulizia in modalità simulazione (dry-run)?" --ok-label="Sì" --cancel-label="No"; then
        DRY_RUN="true"
    else
        DRY_RUN="false"
    fi

    if [ "${DRY_RUN}" != "true" ]; then
        if command -v pkexec &>/dev/null; then
            # pkexec spesso resetta l'ambiente; passiamo le variabili essenziali
            exec env DRY_ESCALATED=1 pkexec env DISPLAY="${DISPLAY:-}" XAUTHORITY="${XAUTHORITY:-}" bash "$0" "$@"
        else
            exec env DRY_ESCALATED=1 sudo -E bash "$0" "$@"
        fi
    fi
else
    # Se siamo già root o dry-run, conferma dry-run (se non impostato)
    if [ "${DRY_RUN:-}" != "true" ] && [ "${DRY_RUN:-}" != "false" ]; then
        if zenity --question --title="Pulizia Sistema" --text="Vuoi eseguire la pulizia in modalità simulazione (dry-run)?" --ok-label="Sì" --cancel-label="No"; then
            DRY_RUN="true"
        else
            DRY_RUN="false"
        fi
    fi
fi

# Trap per pulire in caso di interruzione
on_abort() {
    zenity --warning --title="Annullato" --text="Pulizia annullata dall'utente."
    exit 1
}
trap 'on_abort' TERM INT

DRY_SUMMARY=""

# Produzione dei messaggi di progresso (non aprire altre finestre zenity qui)
(
echo "0"; sleep 0.2

# 1. Autoremove + purge
if [ "${DRY_RUN}" = "true" ]; then
    DRY_SUMMARY+="🔄 [Dry-run] Verifica dei pacchetti da rimuovere (apt autoremove --purge)\n"
else
    echo "10"; sleep 0.1
    apt -y autoremove --purge
fi
echo "20"; sleep 0.1

# 2. Autoclean
if [ "${DRY_RUN}" = "true" ]; then
    DRY_SUMMARY+="🗑️ [Dry-run] Pulizia dei pacchetti obsoleti (apt autoclean)\n"
else
    echo "30"; sleep 0.1
    apt -y autoclean
fi
echo "50"; sleep 0.1

# 3. Clean
if [ "${DRY_RUN}" = "true" ]; then
    DRY_SUMMARY+="🧹 [Dry-run] Pulizia completa della cache APT (apt clean)\n"
else
    echo "60"; sleep 0.1
    apt clean
fi
echo "70"; sleep 0.1

# 4. Journald
if [ "${DRY_RUN}" = "true" ]; then
    DRY_SUMMARY+="📜 [Dry-run] Rimozione log journald più vecchi di 7 giorni (journalctl --vacuum-time=7d)\n"
else
    echo "75"; sleep 0.1
    journalctl --vacuum-time=7d || true
fi
echo "85"; sleep 0.1

# 5. Cache miniature
THUMB_DIR="${HOME}/.cache/thumbnails"
if [ -d "${THUMB_DIR}" ]; then
    if [ "${DRY_RUN}" = "true" ]; then
        NUM_FILES=$(find "${THUMB_DIR}" -type f | wc -l)
        DRY_SUMMARY+="🖼️ [Dry-run] Cache miniature: ${NUM_FILES} file verrebbero rimossi.\n"
    else
        echo "90"; sleep 0.1
        # Rimuove solo il contenuto della directory, preservandone la struttura
        find "${THUMB_DIR}" -mindepth 1 -delete || true
    fi
fi
echo "100"; sleep 0.1

) | zenity --progress \
           --title="Pulizia Sistema" \
           --text="Pulizia in corso..." \
           --percentage=0 \
           --auto-close

# salva lo stato della pipe immediatamente
PIPE_STATUS=("${PIPESTATUS[@]}")

# Controlla se zenity è stato annullato (indice 1 della pipe)
if [ "${PIPE_STATUS[1]:-0}" -ne 0 ]; then
    zenity --warning --title="Annullato" --text="Pulizia annullata dall'utente."
    exit 1
fi

# Fine: mostra riepilogo per dry-run o conferma
if [ "${DRY_RUN}" = "true" ]; then
    if [ -z "${DRY_SUMMARY}" ]; then
        zenity --info --title="Dry-run completato" --text="Nessuna azione da simulare."
    else
        # se il riepilogo è lungo, usare text-info con file temporaneo
        TMP=$(mktemp)
        printf '%b\n' "${DRY_SUMMARY}" > "${TMP}"
        zenity --text-info --title="Dry-run - Azioni simulate" --filename="${TMP}" --width=600 --height=400
        rm -f "${TMP}"
    fi
else
    zenity --info --title="Pulizia completata" --text="✅ Pulizia del sistema completata!"
fi
# ...existing code...
