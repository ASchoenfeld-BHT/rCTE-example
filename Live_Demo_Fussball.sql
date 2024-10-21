-- Tabelle erstellen und fuellen
USE test;

DROP TABLE IF EXISTS liveDemo_fussball;
CREATE TABLE liveDemo_fussball (
    ID INT,
    Verein VARCHAR(50),
    Uebergeordneten_Tabellenplatz INT,
    Tordifferenz INT,
    Liga INT
);

INSERT INTO liveDemo_fussball (ID, Verein, Uebergeordneten_Tabellenplatz, Tordifferenz, Liga)
VALUES
	(17, 'Eintracht Frankfurt', 0, 2, 1),
    (5, 'Borussia Dortmund', 17, 4, 1),
    (13, 'FC Schalke 04', 8, 10, 2),
    (43, 'Hansa Rostock', 0, 6, 3),
    (9, 'VfL Bochum 1848', 5, 2, 1),
    (8, 'Hamburger SV', 76, 2, 2),
    (19, 'Saarbrücken', 0, 5, 3),
    (12, 'VfB Stuttgart', 17, 8, 1),
    (76, 'SC Paderborn 07', 0, 5, 2),
    (54, 'VfL Osnabrück', 0, 1, 3)
;

-- Tabelle strukturieren
SELECT * FROM liveDemo_fussball;
SELECT * FROM liveDemo_fussball WHERE Liga=1;
SELECT * FROM liveDemo_fussball WHERE Liga=2;
SELECT * FROM liveDemo_fussball WHERE Liga=3;


-- Iterative Abfrage, wie in TYPO3
SELECT * FROM liveDemo_fussball WHERE Liga=1 AND Uebergeordneten_Tabellenplatz=0;
SELECT * FROM liveDemo_fussball WHERE Liga=1 AND Uebergeordneten_Tabellenplatz=17;
SELECT * FROM liveDemo_fussball WHERE Liga=1 AND Uebergeordneten_Tabellenplatz=17 ORDER BY Tordifferenz DESC;
SELECT * FROM liveDemo_fussball WHERE Liga=1 AND Uebergeordneten_Tabellenplatz=5 ORDER BY Tordifferenz DESC;




-- CTE Beispiel
-- Temporaere Tabellen nutzen andere temp. Tabellen
WITH
	Liga1 AS (
		SELECT * FROM liveDemo_fussball WHERE Liga=1
	),
    Tabellenfuehrer_Liga1 AS (
		SELECT * FROM Liga1 WHERE Uebergeordneten_Tabellenplatz=0
	)
SELECT * FROM Tabellenfuehrer_Liga1;



-- rCTE Beispiel
-- Alle Ligateilnehmer rekursiv abfragen
-- Problem: Wie den Output sortieren?
WITH RECURSIVE Liga1_Tabelle AS (
	SELECT
		ID, 
        Verein, 
        Uebergeordneten_Tabellenplatz, 
        Tordifferenz, 
        Liga
	FROM liveDemo_fussball topSelect
	WHERE Uebergeordneten_Tabellenplatz=0 AND Liga=1
	
    UNION ALL
	
    SELECT
		subSelect.ID, 
        subSelect.Verein, 
        subSelect.Uebergeordneten_Tabellenplatz, 
        subSelect.Tordifferenz, 
        subSelect.Liga
	FROM liveDemo_fussball subSelect
	INNER JOIN Liga1_Tabelle topSelect ON topSelect.id = subSelect.Uebergeordneten_Tabellenplatz
    WHERE subSelect.Liga=1
)
SELECT * FROM Liga1_Tabelle;




-- rCTE Beispiel (width first)
-- Alle Ligateilnehmer rekursiv abfragen
-- Sortierung pro Ebene = Ebene1 (nach Tordiff. sortiert), Ebene2 (nach Tordiff. sortiert)...
-- Hilfspalte 'Rang' für Sortierung erstellt
WITH RECURSIVE Liga1_Tabelle AS (
	SELECT
		ID, 
        Verein, 
        Uebergeordneten_Tabellenplatz, 
        Tordifferenz, 
        Liga,
        1 as Rang
	FROM liveDemo_fussball topSelect
	WHERE Uebergeordneten_Tabellenplatz=0 AND Liga=1
	
    UNION ALL
	
    SELECT
		subSelect.ID, 
        subSelect.Verein, 
        subSelect.Uebergeordneten_Tabellenplatz, 
        subSelect.Tordifferenz, 
        subSelect.Liga,
        topSelect.Rang+1
	FROM liveDemo_fussball subSelect
	INNER JOIN Liga1_Tabelle topSelect ON topSelect.id = subSelect.Uebergeordneten_Tabellenplatz
    WHERE subSelect.Liga=1
)
SELECT * FROM Liga1_Tabelle ORDER BY Rang ASC, Tordifferenz DESC;





-- rCTE Beispiel (depth first)
-- Alle Ligateilnehmer rekursiv abfragen
-- Sortierung pro Zweig = Ebene1 (beste Tordiff.), Ebene2 (beste Tordiff.), Ebene2 (zweitbeste Tordiff.), Ebene3 (beste Tordiff.), ...
-- Hilfspalte 'Sortierung' für Sortierung erstellt um Gesamtstring am Ende lexikalisch zu sortieren - 100-Tordifferenz um Tordiff. umzukehren
-- Jeder Zweig wird bis zum Ende durchlaufen bevor der naechste Zweig durchlaufen wird
WITH RECURSIVE Liga1_Tabelle AS (
	SELECT
		ID, 
        Verein, 
        Uebergeordneten_Tabellenplatz, 
        Tordifferenz, 
        Liga,
        CAST(LPAD(100-Tordifferenz,6,'0') AS CHAR(200)) as 'Sortierung'
	--  CAST(LPAD(D.sorting,10,'0') AS CHAR(200)) as '__CTE_SORTING__',
	FROM liveDemo_fussball topSelect
	WHERE Uebergeordneten_Tabellenplatz=0 AND Liga=1
	
    UNION ALL
	
    SELECT
		subSelect.ID, 
        subSelect.Verein, 
        subSelect.Uebergeordneten_Tabellenplatz, 
        subSelect.Tordifferenz, 
        subSelect.Liga,
        CONCAT(topSelect.Sortierung,'/',LPAD(100-subSelect.Tordifferenz,6,'0')) as 'Sortierung'
	--  CONCAT(R.__CTE_SORTING__,'/',LPAD(D.sorting,10,'0')) as '__CTE_SORTING__',
	FROM liveDemo_fussball subSelect
	INNER JOIN Liga1_Tabelle topSelect ON topSelect.id = subSelect.Uebergeordneten_Tabellenplatz
    WHERE subSelect.Liga=1
)
SELECT * FROM Liga1_Tabelle ORDER BY Sortierung ASC;
        
        







-- rCTE innerhalb CTE Beispiel
-- Achtung: Richtige (virtuelle) Tabelle nutzen
-- und an der richtigen Stelle sortieren
WITH
	Liga1 AS (
		SELECT * FROM liveDemo_fussball WHERE Liga=1
	),
    Liga2 AS (
		SELECT * FROM liveDemo_fussball WHERE Liga=2
	),
    Liga3 AS (
		SELECT * FROM liveDemo_fussball WHERE Liga=3
	),
    Liga1_Tabelle AS (
		WITH RECURSIVE Liga1_Tabelle_recursive AS (
			SELECT
				ID, 
				Verein, 
				Uebergeordneten_Tabellenplatz, 
				Tordifferenz, 
				Liga,
				1 as Rang,
                CAST(LPAD(100-Tordifferenz,6,'0') AS CHAR(200)) as 'Sortierung'
			FROM Liga1 topSelect
			WHERE Uebergeordneten_Tabellenplatz=0
			
			UNION ALL
			
			SELECT
				subSelect.ID, 
				subSelect.Verein, 
				subSelect.Uebergeordneten_Tabellenplatz, 
				subSelect.Tordifferenz, 
				subSelect.Liga,
				topSelect.Rang+1,
                CONCAT(topSelect.Sortierung,'/',LPAD(100-subSelect.Tordifferenz,6,'0')) as 'Sortierung'
			FROM Liga1 subSelect
			INNER JOIN Liga1_Tabelle_recursive topSelect ON topSelect.id = subSelect.Uebergeordneten_Tabellenplatz
		)
        SELECT * FROM Liga1_Tabelle_recursive
        -- Sortierung an dieser Stelle vermeiden und stattdessen am Ende der Query vornehmen!!!
		-- SELECT * FROM Liga1_Tabelle ORDER BY Rang ASC, Tordifferenz DESC
)
-- An dieser Stelle sortieren
-- SELECT * FROM Liga1_Tabelle ORDER BY Sortierung ASC; -- (depth first)
SELECT * FROM Liga1_Tabelle ORDER BY Rang ASC, Tordifferenz DESC; -- (width first)
