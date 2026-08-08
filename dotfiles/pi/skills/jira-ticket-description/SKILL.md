---
name: jira-ticket-description
description: "Tworzy po polsku gotową treść opisu zadania Jira w układzie CEL, PLAN DZIAŁANIA i WYNIK. Użyj, gdy użytkownik prosi o opis, treść lub ticket do Jira."
---

# Opis zadania Jira

Na podstawie polecenia użytkownika przygotuj **wyłącznie gotową treść opisu ticketa Jira po polsku**. Nie wykonuj opisanego zadania, nie zmieniaj plików, nie przeszukuj repozytorium i nie dodawaj żadnego komentarza, wstępu, tytułu Jira, metadanych ani wyjaśnień przed lub po opisie.

## Format odpowiedzi

Użyj dokładnie poniższej struktury:

```text
CEL:
[Krótki, konkretny opis celu w 1–2 zdaniach. Opisuj rezultat, zakres i ważne ograniczenia.]

────────────────────────────────────────────────────────────────────────────────

PLAN DZIAŁANIA:

[Nazwa obszaru prac]
◉ [Konkretny krok lub wymaganie]
◉ [Konkretny krok lub wymaganie]

[Następny obszar prac — tylko gdy jest potrzebny]
◉ [Konkretny krok lub wymaganie]

────────────────────────────────────────────────────────────────────────────────

WYNIK:

◉ [Weryfikowalny efekt końcowy]
◉ [Kolejny istotny efekt lub kryterium akceptacji]
```

## Zasady redakcyjne

- Zawsze zachowaj sekcje `CEL:`, `PLAN DZIAŁANIA:` i `WYNIK:` oraz oba separatory.
- Pisz rzeczowo i profesjonalnie, po polsku, w formie bezokoliczników lub konkretnych rezultatów.
- W sekcji **CEL** określ, co ma powstać lub zostać osiągnięte, dla jakiego kontekstu oraz z jakimi istotnymi ograniczeniami.
- W sekcji **PLAN DZIAŁANIA** pogrupuj kroki w logiczne obszary. Każdy punkt rozpocznij znakiem `◉`; stosuj nagłówki obszarów tylko, jeśli poprawiają czytelność.
- W sekcji **WYNIK** podaj wyłącznie mierzalne lub możliwe do zweryfikowania rezultaty i kryteria akceptacji. Każdy punkt rozpocznij znakiem `◉`.
- Ujmij technologie, integracje, bezpieczeństwo, testy, automatyzację i dokumentację tylko wtedy, gdy wynikają z polecenia.
- Zachowaj nazwy własne technologii, wersje, liczby i ograniczenia podane przez użytkownika.
- Nie wymyślaj szczegółów technicznych, liczb, terminów ani technologii, których użytkownik nie podał lub które nie wynikają jednoznacznie z kontekstu.
- Jeśli wejście jest krótkie, sformułuj zwięzły, kompletny opis na podstawie dostępnych informacji; nie zadawaj pytań.
- Nie stosuj checklist Markdown (`- [ ]`) ani numeracji. Nie używaj emotikonów poza wymaganym symbolem `◉`.
- Odpowiedź ma zawierać wyłącznie sam opis ticketa — bez bloków kodu Markdown, cytowania polecenia, tekstu typu „Oto opis” ani propozycji dalszych działań.
