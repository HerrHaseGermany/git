# GitHub Activity für macOS

Native SwiftUI-App mit WidgetKit-Widget für macOS 14 oder neuer. Der Beitragskalender wird direkt von GitHub geladen, ohne iPhone. Auf diesem Mac ist die offizielle GraphQL-API über die vorhandene GitHub-Anmeldung verbunden; der Zugang liegt im macOS-Schlüsselbund.

## Benutzen

1. GitHub Activity öffnen. In der App kann ein GitHub-Benutzername eingegeben und eine Vorschau geladen werden.
2. Rechtsklick auf den Schreibtisch → Widgets bearbeiten → GitHub Activity hinzufügen.
3. In der App den gewünschten GitHub-Benutzernamen laden. Das Widget übernimmt ihn automatisch und aktualisiert sich.

Widgets verwenden standardmäßig das zuletzt erfolgreich in der App geladene Profil. Der gemeinsame Profilname liegt in einem Schlüsselbund-Eintrag mit Zugriff für App und Widget. Ein zusätzlicher Ladevorgang in den Widget-Einstellungen ist nicht erforderlich. Falls ein Widget bewusst ein anderes Profil anzeigen soll, kann „Profil aus der App übernehmen“ ausgeschaltet und sein eigener Benutzername gesetzt werden.

App und Widget folgen der bevorzugten Systemsprache und unterstützen Deutsch und Englisch. Andere Sprachen verwenden Englisch als Fallback.

Das breite Widget zeigt 16 Wochen mit sieben Tageszeilen, das kleine sieben Wochen. Bei aktiver API-Verbindung werden Tageszahlen und Aktivitätsstufen unverändert aus GitHubs API übernommen. Die Abfrage umfasst den dargestellten Zeitraum; der Renderer skaliert die API-Stufen nicht erneut. Im getönten Modus bleiben diese Stufen über fünf unterschiedliche Deckkraftwerte sichtbar; im lebendigen Modus werden sie als Graustufen dargestellt. Ein Linksklick führt eine Hintergrundaktion direkt in der Widget-Erweiterung aus und öffnet das konfigurierte Profil im Standardbrowser. Die Haupt-App und ihr Vorschaufenster werden dabei nicht gestartet. Wird die App über Programme gestartet, bleibt die Vorschau verfügbar.

## Daten

Bei gespeicherter API-Verbindung lädt die App `https://api.github.com/graphql`. Abgefragt werden ausschließlich Datum, Beitragszahl und Aktivitätsstufe; Repository-Inhalte werden nicht geladen. Ohne eingerichtete Verbindung steht der öffentliche HTML-Kalender als Rückfallquelle bereit. Ein Zugriffsfehler auf eine gespeicherte Verbindung wird als Fehler gemeldet; es erfolgt dabei kein stiller Wechsel zur HTML-Quelle.

WidgetKit erhält eine Aktualisierungsanforderung nach einer Stunde; macOS bestimmt den tatsächlichen Zeitpunkt. Bei einem Netzwerkfehler bleibt der zuletzt erfolgreich geladene Kalender dieses Profils erhalten und wird mit einem kleinen Symbol markiert.

## Bauen und installieren

Xcode und ein gültiges Apple-Development-Zertifikat im lokalen Schlüsselbund erforderlich:

```sh
./scripts/build.sh
./scripts/install.sh
```

Das Build-Skript verwendet automatisch ein vorhandenes Apple-Development-Zertifikat. Alternativ kann `GITHUB_ACTIVITY_SIGNING_IDENTITY` gesetzt werden. Eine Ad-hoc-Signatur ohne TeamIdentifier wurde vom App-Intents-Dienst dieses Macs zurückgewiesen.

Der Build liegt standardmäßig unter `/tmp/GitHubActivity-build`; `GITHUB_ACTIVITY_BUILD_DIR` kann den Pfad ändern. Das Installationsskript beendet nur die App und ihre Widget-Erweiterung, installiert nach Programme und aktualisiert die Registrierung. So bleibt nach Updates keine alte Erweiterung mit veralteten Intent-Parametern im Speicher.

Beim Wechsel von einer früheren Version mit Profilauswahl auf das Textfeld das Widget bei Bedarf entfernen und neu hinzufügen, damit macOS die neue Konfiguration verwendet.

Parser-Prüfung mit echtem GitHub-Abruf:

```sh
swiftc -parse-as-library Shared/Contributions.swift Shared/GitHubAPI.swift Tests/ParserCheck.swift -o /tmp/github-parser-check
/tmp/github-parser-check
```

Das Xcode-Projekt kann direkt geöffnet werden. Es lässt sich bei Bedarf mit `python3 scripts/generate_project.py` neu erzeugen.

## Textfeld-Darstellung

Die Haupt-App zeigt am Benutzernamenfeld einen dauerhaften Rahmen und einen blauen Fokusrahmen. Der systemeigene Dialog „Widget bearbeiten“ wird von macOS aus den Intent-Parametern erzeugt; Rahmen und Cursor-Darstellung dieses Dialogs lassen sich durch WidgetKit nicht anpassen.

## Icon

Das bereitgestellte Original liegt unter `Resources/Artwork/AppIcon.png`. `scripts/generate_icon.swift` erstellt daraus `Resources/AppIcon.icns` mit den macOS-Icon-Größen. Seitenverhältnis und Transparenz bleiben erhalten. Das Build-Skript erzeugt zusätzlich `Resources/Assets.xcassets/AppIcon.appiconset` mit allen macOS-Größen. Xcode kompiliert diesen App-Icon-Katalog für App und Widget-Erweiterung; `CFBundleIconName` verweist auf das Icon. Die klassische ICNS-Datei bleibt als exportierbares Artefakt erhalten.

## Liquid Glass

Im normalen Farbmodus verwendet das Widget einen dunklen Verlauf und die aus dem bereitgestellten Original ausgelesenen Aktivitätsfarben. Im getönten Modus bleibt das ultra-dünne Systemmaterial mit einer dezenten Kante erhalten. Für die getönte/klare Darstellung übernimmt WidgetKit das native Liquid-Glass-Material; die fünf Aktivitätsstufen bleiben über unterschiedliche Deckkraft erhalten. Der Widget-Klick ist ein flächiger, rahmenloser App-Intent-Button mit `openAppWhenRun = false`. Die frühere Weiterleitung über ein App-Fenster und ein eigenes URL-Schema wurde entfernt.

Apple aktiviert die automatische Liquid-Glass-Hintergrunddarstellung für den klaren/getönten Modus (`accented`). Im normalen Farbmodus wird das nicht automatisch übernommen. Die vorherige Aussage, dass ein Material-Hintergrund echte Liquid-Glass-Darstellung auch im Farbmodus garantiert, war zu weitgehend. Referenz: https://developer.apple.com/documentation/widgetkit/optimizing-your-widget-for-accented-rendering-mode-and-liquid-glass

## Farben des Originals

`Shared/WidgetAppearance.swift` enthält die gemeinsame Farbpalette und den dunklen Verlauf für Widget und App-Vorschau. Die sRGB-Werte wurden aus der Originalaufnahme mit Berücksichtigung des eingebetteten Farbprofils abgeleitet: `#0D1117`, `#012D11`, `#054F1E`, `#1B7F37`, `#2BA44E`. Die Graustufen verwenden weiterhin abgestufte Deckkraft.

## Prüfung von Daten und Icons

Seit Version 1.9 werden Tageszahlen aus den Kalender-Tooltips gelesen. Die Farbintensität skaliert relativ zum Maximum des sichtbaren Zeitraums. Zukünftige Kalendertage werden vor der Darstellung ausgeschlossen. Alte Cache-Dateien ohne Tageszahlen bleiben lesbar und verwenden bis zum nächsten erfolgreichen Abruf ihre gespeicherten Intensitäten.

Die Widget-Galerie dieses Macs löste die gemischt geschriebene App-Kennung `de.raudzis.GitHubActivity` als Platzhalter auf. Die Diagnose über denselben Galerie-Resolver (`CHSIconResolver` / `CHSWidgetExtensionContainer`) zeigte dagegen für `de.raudzis.githubactivity` das richtige Icon. Eine korrekte Finder-Darstellung allein reichte als Prüfung nicht aus. Cache-Neustarts und eine direkte ICNS-Einbindung behoben den Galeriefehler nicht.

Seit Build 19 verwenden App und Erweiterung deshalb kleingeschriebene Bundle-Kennungen. Die ursprünglichen Code-Signaturkennungen bleiben über `OTHER_CODE_SIGN_FLAGS --identifier` erhalten, damit bestehende Schlüsselbund-Zugriffsregeln weiterhin passen. Der Build erfüllt die bisherigen Designated Requirements beider Programme; das gespeicherte Profil und die authentifizierte API-Abfrage wurden anschließend erfolgreich geprüft. Die richtige Icon-Anzeige in der Galerie wurde bestätigt. Der Assetkatalog bleibt die Icon-Quelle.

Apple beschreibt [Bundle-Kennungen als unabhängig von Groß-/Kleinschreibung](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleidentifier). Die abweichende Galerie-Auflösung wurde auf diesem Mac direkt nachgewiesen; daraus folgt keine allgemeine Pflicht zu kleingeschriebenen Kennungen. Die Bedeutung der gesonderten Signaturkennung erläutert [TN3127: Inside Code Signing: Requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).

Ein Vergleich mit dem Original-Screenshot zeigt zusätzlich einzelne aktive Tage, die in der aktuellen öffentlichen GitHub-Abfrage und der authentifizierten API-Abfrage nicht vorkommen. Diese verbleibende Abweichung ist nicht erklärt; das Widget ergänzt deshalb keine erfundenen Beiträge.

## Farbmodus auf dem Schreibtisch

macOS kann den deklarieren `containerBackground` auch im Farbmodus entfernen. Seit Version 1.10 liegt der dunkle Farbverlauf deshalb im Inhaltsbereich hinter dem Raster und wird nur im Farbmodus gezeichnet. Im getönten Modus übernimmt weiterhin das System den Hintergrund.

Das Original-Widget steht auf dem Mac. Die Mac-Protokolle identifizieren es als GitHubs Erweiterung `com.github.stormbreaker.prod.widgets-contribution-graph`; eine separat auf dem iPhone platzierte Widget-Instanz ist nicht nötig. Die Ursache der abweichenden aktiven Tage ist weiterhin nicht nachgewiesen.

## API-Verbindung seit Version 2.0

`Shared/GitHubAPI.swift` lädt den strukturierten Kalender über GitHubs offizielle GraphQL-API. Auf diesem Mac wurde die bereits vorhandene GitHub-CLI-Anmeldung nach Zustimmung in einen separaten Schlüsselbund-Eintrag übernommen (`de.raudzis.GitHubActivity.github-api`). Seine Zugriffsliste erlaubt die installierte App und ihre Widget-Erweiterung. Es werden keine Zugangsdaten in Dateien, Protokollen oder Widget-Einstellungen gespeichert.

Die App bestätigt eine erfolgreiche API-Ladung mit „Mit GitHub-API verbunden“. Der Logger meldet lediglich Datenquelle und Anzahl der geladenen Tage; keine Zugangsdaten und keine Repository-Daten. Die Funktionsprüfung bestätigte eine erfolgreiche authentifizierte API-Ladung sowohl im App-Prozess als auch im Widget-Prozess.

`Tests/APICalendarCheck.swift` prüft die strukturierten API-Antworten und die unveränderte Übernahme der GitHub-Stufen:

```sh
swiftc -parse-as-library Shared/Contributions.swift Shared/GitHubAPI.swift Tests/APICalendarCheck.swift -o /tmp/github-api-calendar-check
/tmp/github-api-calendar-check
```

## Profilübernahme und universelle API-Abfrage (2.1)

Die GraphQL-Abfrage verwendet die Variable `login` aus dem eingegebenen Profilnamen. Es gibt keinen fest verdrahteten Zielbenutzer. Der laufende Test lud das fremde Konto `torvalds` erfolgreich über die installierte App und stellte anschließend `HerrHaseGermany` wieder her. App und Widget luden nach beiden Profilwechseln neue API-Kalender. Der API-Zugang wird für die Verbindung verwendet, der Zielprofilname für die Abfrage.

Die API-Stufen `NONE`, `FIRST_QUARTILE`, `SECOND_QUARTILE`, `THIRD_QUARTILE`, `FOURTH_QUARTILE` werden unverändert den fünf Farben (dunkel bis hell) zugeordnet. Ein Vertauschen der Stufen wurde nicht festgestellt. Ein vollständig gleiches Muster wie im Original-Screenshot ist weiterhin nicht belegt.
