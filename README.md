
# Ubuntu System Cleanup Script

🧹 Script bash sicuro per la pulizia automatica del sistema Ubuntu 24.04 LTS con interfaccia grafica (Zenity).

## ✨ Caratteristiche

- ✅ Interfaccia grafica user-friendly con Zenity
- 🔒 Richiesta automatica di privilegi amministrativi (pkexec/sudo)
- 🎯 Modalità **dry-run** per simulare le operazioni prima di eseguirle
- 📊 Barra di progresso in tempo reale
- 🛡️ Gestione sicura degli errori e interruzioni
- 🚀 Avviabile con doppio click

## 🔧 Operazioni eseguite

Lo script esegue le seguenti operazioni di pulizia:

1. **Rimozione pacchetti obsoleti** - `apt autoremove --purge`
2. **Pulizia cache vecchia** - `apt autoclean`
3. **Pulizia completa cache APT** - `apt clean`
4. **Pulizia log journald** - Rimuove log più vecchi di 7 giorni
5. **Pulizia cache miniature** - Rimuove le anteprime delle immagini in `~/.cache/thumbnails`

## 📋 Requisiti

- Ubuntu 24.04 LTS (o versioni compatibili)
- Zenity installato
- Privilegi amministrativi (root)

### Installazione dipendenze

```bash
sudo apt update
sudo apt install zenity
```

## 🚀 Utilizzo

### Metodo 1: Doppio click (interfaccia grafica)

1. Scarica lo script `ubuntu-cleanup.sh`
2. Rendilo eseguibile:
   ```bash
   chmod +x ubuntu-cleanup.sh
   ```
3. Fai doppio click sul file e seleziona "Esegui"

### Metodo 2: Da terminale

```bash
# Modalità normale (esegue effettivamente la pulizia)
./ubuntu-cleanup.sh

# Modalità dry-run (simula senza modificare il sistema)
# Verrà chiesto all'avvio tramite finestra di dialogo
```

## 🎮 Modalità Dry-Run

All'avvio, lo script chiede se si desidera eseguire in modalità **simulazione (dry-run)**:

- **Sì**: Mostra cosa verrebbe fatto senza modificare nulla
- **No**: Esegue effettivamente le operazioni di pulizia

La modalità dry-run è utile per:
- Verificare cosa verrà rimosso prima di procedere
- Vedere quanto spazio si può liberare
- Testare lo script in sicurezza

## 🔒 Sicurezza

- Lo script richiede esplicitamente i privilegi amministrativi solo quando necessario
- Utilizza `set -euo pipefail` per gestire errori in modo sicuro
- Include trap per gestire interruzioni dell'utente (Ctrl+C)
- Preserva la struttura delle directory durante la pulizia

## 📸 Screenshot

*(Aggiungi qui screenshot dell'interfaccia quando disponibili)*

## 🤝 Contribuire

I contributi sono benvenuti! Per favore:

1. Fai fork del repository
2. Crea un branch per la tua feature (`git checkout -b feature/AmazingFeature`)
3. Commit delle modifiche (`git commit -m 'Add some AmazingFeature'`)
4. Push al branch (`git push origin feature/AmazingFeature`)
5. Apri una Pull Request

## 📝 Licenza

Questo progetto è distribuito sotto licenza MIT. Vedi il file `LICENSE` per maggiori dettagli.

## ⚠️ Disclaimer

Questo script è fornito "così com'è" senza garanzie di alcun tipo. Utilizzalo a tuo rischio e pericolo. Si consiglia sempre di fare un backup prima di eseguire operazioni di pulizia del sistema.

## 🐛 Segnalazione Bug

Se trovi un bug o hai suggerimenti, apri una [Issue](../../issues) su GitHub.

## 📧 Contatti

Per domande o suggerimenti, apri una discussione nella sezione [Discussions](../../discussions).

---

⭐ Se questo script ti è stato utile, considera di mettere una stella al repository!
