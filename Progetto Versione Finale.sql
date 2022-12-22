SET NAMES latin1;
SET FOREIGN_KEY_CHECKS = 1;

BEGIN;
CREATE DATABASE `Farmhouse`;
COMMIT;

USE `Farmhouse`;


-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                                                                            ||            TABELLE E TRIGGER           ||
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ----------------------------
--  Table structure for `INDIRIZZO`
-- ----------------------------
DROP TABLE IF EXISTS `Indirizzo`;
CREATE TABLE `Indirizzo` (
  `Citta` char(50) NOT NULL,
  `Via` char(50) NOT NULL,
  `NumeroCivico` int(11) NOT NULL,
  `CAP` int(11) NOT NULL,
  PRIMARY KEY (Citta, Via, NumeroCivico)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `AGRITURISMO`
-- ----------------------------
DROP TABLE IF EXISTS `Agriturismo`;
CREATE TABLE `Agriturismo` (
  `Nome` char(50) NOT NULL,
  `Citta` char(50) NOT NULL,
  `Via` char(50) NOT NULL,
  `NumeroCivico` int(11) NOT NULL,
  PRIMARY KEY (Nome),
  CONSTRAINT `FK_Agriturismo_Indirizzo` FOREIGN KEY (Citta, Via, NumeroCivico)
    REFERENCES Indirizzo(Citta, Via, NumeroCivico)
    ON DELETE NO ACTION
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `STALLA`
-- ----------------------------
DROP TABLE IF EXISTS `Stalla`;
CREATE TABLE `Stalla` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Agriturismo` char(50) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Stalla_Agriturismo` FOREIGN KEY (Agriturismo)
    REFERENCES Agriturismo(Nome)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=Latin1;


-- ----------------------------
--  Table structure for `LOCALE`
-- ----------------------------
DROP TABLE IF EXISTS `Locale`;
CREATE TABLE `Locale` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Stalla` int(11) NOT NULL,
  `Pavimentazione` char(50) NOT NULL,
  `InterventoPulizia` bool DEFAULT 0,
  `MaxNumeroAnimali` int(11) DEFAULT NULL,
  `OrientazioneFinestre` char(50) NOT NULL,
  `Altezza` double NOT NULL,
  `Lunghezza` double NOT NULL,
  `Larghezza` double NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Locale_Stalla` FOREIGN KEY (Stalla)
	REFERENCES Stalla(Codice)
	ON UPDATE CASCADE
	ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `PARAMETRI LOCALE`
-- ----------------------------
DROP TABLE IF EXISTS `ParametriLocale`;
CREATE TABLE `ParametriLocale` (
  `Ora` time NOT NULL,
  `Data` date NOT NULL,
  `Locale` int(11) NOT NULL,
  `Temperatura` double NOT NULL,
  `Umidita` double NOT NULL,
  PRIMARY KEY (Ora, Data, Locale),
  CONSTRAINT `FK_ParametriLocale_Locale` FOREIGN KEY (Locale)
    REFERENCES Locale(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `CONDIZIONE LOCALE`
-- ----------------------------
DROP TABLE IF EXISTS `CondizioneLocale`;
CREATE TABLE `CondizioneLocale` (
  `Ora` time NOT NULL,
  `Data` date NOT NULL,
  `Locale` int(11) NOT NULL,
  `Azoto` double NOT NULL,
  `Metano` double NOT NULL,
  `LivelloSporcizia` int(11) NOT NULL,
  PRIMARY KEY (Ora, Data, Locale),
  CONSTRAINT `FK_CondizioneLocale_Locale` FOREIGN KEY (Locale)
    REFERENCES Locale(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- -------------------------------
-- NOTIFICA INTERVENTO PULIZIA
-- -------------------------------
DROP TRIGGER IF EXISTS `NotificaInterventoPulizia`;
DELIMITER $$
CREATE TRIGGER `NotificaInterventoPulizia`
AFTER INSERT ON CondizioneLocale
FOR EACH ROW
  BEGIN
	UPDATE Locale L
	SET L.InterventoPulizia = TRUE
	WHERE L.Codice = NEW.Locale;
  END $$
DELIMITER ;


-- ----------------------------
--  Table structure for `MANGIATOIA`
-- ----------------------------
DROP TABLE IF EXISTS `Mangiatoia`;
CREATE TABLE `Mangiatoia` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Tipologia` char(50) NOT NULL,
  `Locale` int(11) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Mangiatoia_Locale` FOREIGN KEY (Locale)
  REFERENCES Locale(Codice)
  ON UPDATE CASCADE
  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `PASTO`
-- ----------------------------
DROP TABLE IF EXISTS `Pasto`;
CREATE TABLE `Pasto` (
  `Data` date NOT NULL,
  `Ora` time NOT NULL,
  `Mangiatoia` int(11) NOT NULL,
  PRIMARY KEY (Data, Ora, Mangiatoia),
  CONSTRAINT `FK_Pasto_Mangiatoia` FOREIGN KEY (Mangiatoia)
    REFERENCES Mangiatoia(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `FORAGGIO`
-- ----------------------------
DROP TABLE IF EXISTS `Foraggio`;
CREATE TABLE `Foraggio` (
  `Data` date NOT NULL,
  `Ora` time NOT NULL,
  `Mangiatoia` int(11) NOT NULL,
  `Quantita` double NOT NULL,
  `DataPasto` date DEFAULT NULL,
  `OraPasto` time DEFAULT NULL,
  PRIMARY KEY (Data, Ora, Mangiatoia),
  CONSTRAINT `FK_Foraggio_Mangiatoia` FOREIGN KEY (Mangiatoia)
	REFERENCES Mangiatoia(Codice)
	ON UPDATE CASCADE
	ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- ---------------------------------
-- AGGIORNA RIDONDANZA SU FORAGGIO
-- ---------------------------------
DROP TRIGGER IF EXISTS `AggiornaPastoDiForaggio`;
DELIMITER ;;
CREATE TRIGGER `AggiornaPastoDiForaggio` 
BEFORE INSERT ON Foraggio 
FOR EACH ROW 
BEGIN
  DECLARE _dataPasto date DEFAULT NULL;
  DECLARE _oraPasto time DEFAULT NULL;
  
  SELECT P.Data, P.Ora INTO _dataPasto, _oraPasto
  FROM Pasto P
  WHERE P.Mangiatoia = NEW.Mangiatoia
    AND (P.Data < NEW.Data OR (P.Data = NEW.Data AND P.Ora <= NEW.Ora))
    AND NOT EXISTS (
					SELECT *
                    FROM Pasto P2
                    WHERE P2.Mangiatoia = NEW.Mangiatoia
                      AND (P2.Data < NEW.Data OR (P2.Data = NEW.Data AND P2.Ora < NEW.Ora))
                      AND (P.Data < P2.Data OR (P.Data = P2.Data AND P.Ora < P2.Ora))
				   );
                   
  SET NEW.DataPasto = _dataPasto;
  SET NEW.OraPasto = _oraPasto;

END;
;;
DELIMITER ;


-- ----------------------------
--  Table structure for `INGREDIENTE_FORAGGIO`
-- ----------------------------
DROP TABLE IF EXISTS `IngredienteForaggio`;
CREATE TABLE `IngredienteForaggio` (
  `Nome` char(50) NOT NULL,
  `Modalita` char(50) NOT NULL,
  `Fibre` double NOT NULL,
  `Kcal` double NOT NULL,
  `Glucidi` double NOT NULL,
  `Proteine` double NOT NULL,
  PRIMARY KEY (Nome, Modalita)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `COMPOSIZIONE`
-- ----------------------------
DROP TABLE IF EXISTS `Composizione`;
CREATE TABLE `Composizione` (
  `DataPasto` date NOT NULL,
  `OraPasto` time NOT NULL,
  `Mangiatoia` int(11) NOT NULL,
  `NomeIngrediente` char(50) NOT NULL,
  `ModalitaIngrediente` char(50) NOT NULL,
  `Quantita` double NOT NULL, 
  PRIMARY KEY (DataPasto, OraPasto, Mangiatoia, NomeIngrediente, ModalitaIngrediente),
  CONSTRAINT `FK_Composizione_Pasto` FOREIGN KEY (DataPasto, OraPasto, Mangiatoia)
    REFERENCES Pasto(Data, Ora, Mangiatoia)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_Composizione_IngredienteForaggio` FOREIGN KEY (NomeIngrediente, ModalitaIngrediente)
    REFERENCES IngredienteForaggio(Nome, Modalita)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ABBEVERATOIO`
-- ----------------------------
DROP TABLE IF EXISTS `Abbeveratoio`;
CREATE TABLE `Abbeveratoio` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Tipologia` char(50) NOT NULL,
  `Locale` int(11) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Abbeveratoio_Locale` FOREIGN KEY (Locale)
	REFERENCES Locale(Codice)
	ON UPDATE CASCADE
	ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `SOSTANZA`
-- ----------------------------
DROP TABLE IF EXISTS `Sostanza`;
CREATE TABLE `Sostanza` (
  `Nome` char(50) NOT NULL,
  `Data` date NOT NULL,
  `Ora` time NOT NULL,
  `Abbeveratoio` int(11) NOT NULL,
  `Quantita` double NOT NULL,
  PRIMARY KEY (Nome, Data, Ora, Abbeveratoio),
  CONSTRAINT `FK_Sostanza_Abbeveratoio` FOREIGN KEY (Abbeveratoio)
    REFERENCES Abbeveratoio(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ILLUMINAZIONE`
-- ----------------------------
DROP TABLE IF EXISTS `Illuminazione`;
CREATE TABLE `Illuminazione` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Tipologia` char(50) NOT NULL,
  `Intensita` int(11) NOT NULL,
  `ColoreLuce` char(50) NOT NULL,
  `Locale` int(11) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Illuminazione_Locale` FOREIGN KEY (Locale)
	REFERENCES Locale(Codice)
	ON UPDATE CASCADE
	ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `CONDIZIONAMENTO`
-- ----------------------------
DROP TABLE IF EXISTS `Condizionamento`;
CREATE TABLE `Condizionamento` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Tipologia` char(50) NOT NULL,
  `Potenza` int(11) NOT NULL,
  `Locale` int(11) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Condizionamento_Locale` FOREIGN KEY (Locale)
    REFERENCES Locale(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `SPECIE`
-- ----------------------------
DROP TABLE IF EXISTS `Specie`;
CREATE TABLE `Specie` (
  `Specie` char(50) NOT NULL,
  `Famiglia` char(50) NOT NULL,
  PRIMARY KEY (Specie)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `RAZZA`
-- ----------------------------
DROP TABLE IF EXISTS `Razza`;
CREATE TABLE `Razza` (
  `Razza` char(50) NOT NULL,
  `Specie` char(50) NOT NULL,
  PRIMARY KEY (Razza),
  CONSTRAINT `FK_Razza_Specie` FOREIGN KEY (Specie)
    REFERENCES Specie(Specie)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ANIMALE`
-- ----------------------------
DROP TABLE IF EXISTS `Animale`;
CREATE TABLE `Animale` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Razza` char(50) NOT NULL,
  `Sesso` char(50) NOT NULL,
  `Altezza` double DEFAULT NULL,	-- sono nullabili perche possono essere info appartenenti ad animali acquistati da fornitori ma non ancora arrivati in agriturismo, dunque non misurabili
  `Peso` double DEFAULT NULL,
  `Locale` int(11) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Animale_Locale` FOREIGN KEY (Locale)
	REFERENCES Locale(Codice)
	ON UPDATE CASCADE
	ON DELETE NO ACTION,
  CONSTRAINT `FK_Animale_Razza` FOREIGN KEY (Razza)
    REFERENCES Razza(Razza)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- ----------------------------------
-- FUNCTION CalcolaCapienzaLocale
-- ----------------------------------
DROP FUNCTION IF EXISTS `CalcolaCapienzaLocale`;
DELIMITER $$
CREATE FUNCTION `CalcolaCapienzaLocale`( _specie CHAR(50),
                                   	    _lunghezza DOUBLE,
                                    	_larghezza DOUBLE
   								       )
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE MetraggioUnitaSpecie INT DEFAULT 0;
  DECLARE MaxNumAnimali INT DEFAULT 0;
 
  CASE
	WHEN _specie = 'Bovina' THEN
  	SET MetraggioUnitaSpecie = 5;
	WHEN _specie = 'Caprina' THEN
  	SET MetraggioUnitaSpecie = 3;
    WHEN _specie = 'Ovina' THEN
  	SET MetraggioUnitaSpecie = 4;
  END CASE;
 
  SET MaxNumAnimali = (_lunghezza*_larghezza)/MetraggioUnitaSpecie;
    
  RETURN(MaxNumAnimali);
END $$
DELIMITER ;
-- -----------------------------------------------
-- CONTROLLO SUL CORRETTO INSERIMENTO DI UN ANIMALE 
-- -----------------------------------------------
DROP TRIGGER IF EXISTS `checkOspitabilitaAnimale`;
DELIMITER ;;
CREATE TRIGGER `checkOspitabilitaAnimale` 
BEFORE INSERT ON Animale
FOR EACH ROW 			
BEGIN
  DECLARE _specie char(50) DEFAULT'';
  DECLARE _larghezza double DEFAULT 0;
  DECLARE _lunghezza double DEFAULT 0;
  
   SELECT R.Specie INTO _specie
   FROM Razza R
   WHERE R.Razza = NEW.Razza;

-- Controllo della specie dell'animale
  IF _specie NOT LIKE 'bovina' AND _specie NOT LIKE 'ovina' AND _specie NOT LIKE 'caprina' THEN
     SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'Specie animale non valida: sono accettati animali di specie bovina, ovina o caprina';
     
-- Controllo della presenza di altri animali nel locale: se il locale è vuoto, il nuovo animale ne stabilisce la specie ospitata  
  ELSEIF NEW.Locale NOT IN ( SELECT Locale 
                              FROM Animale )  THEN 
     SET @numeroAnimali = 0;
  -- Aggiornamento dell'attributo MaxNumeroAnimali del locale, poiché ospita una nuova specie     
     SELECT Larghezza, Lunghezza INTO _larghezza, _lunghezza
     FROM Locale 
     WHERE Codice = NEW.Locale;
     UPDATE Locale
     SET MaxNumeroAnimali =  CalcolaCapienzaLocale(_specie, _lunghezza, _larghezza)
     WHERE Codice = NEW.Locale;
     
-- Controllo se l'animale inserito nel locale è della stessa specie degli animali attualmente ospitati      
  ELSEIF _specie NOT LIKE ( SELECT R.Specie
						     FROM Razza R NATURAL JOIN Animale A
                             WHERE A.Locale = NEW.Locale
                             LIMIT 1 ) THEN
	 SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'Animale di una specie diversa da quella ospitata nel locale';
     
  ELSE 
     SET @numeroAnimali = ( SELECT count(*) 
							FROM Animale A 
                            WHERE A.Locale = NEW.Locale );

  END IF;
  
  IF @numeroAnimali = ( SELECT L.MaxNumeroAnimali
                        FROM Locale L   
                        WHERE L.Codice = NEW.Locale ) THEN
	 SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'Numero massimo di animali ospitabili superato';
  END IF;
  
END;
;;
DELIMITER ;
-- -----------------------------------------------
-- CONTROLLO SUL CORRETTO TRASFERIMENTO DI UN ANIMALE DA UN LOCALE AD UN ALTRO
-- -----------------------------------------------
DROP TRIGGER IF EXISTS `checkTrasferimentoAnimale`;
DELIMITER ;;
CREATE TRIGGER `checkTrasferimentoAnimale` 
BEFORE UPDATE ON Animale
FOR EACH ROW 			
BEGIN
  DECLARE _specie char(50) DEFAULT'';
  DECLARE _larghezza double DEFAULT 0;
  DECLARE _lunghezza double DEFAULT 0;

 IF (OLD.Locale <> NEW.Locale) THEN
   
   SELECT R.Specie INTO _specie
   FROM Razza R
   WHERE R.Razza = NEW.Razza;
     
-- Controllo della presenza di altri animali nel locale: se il locale è vuoto, il nuovo animale ne stabilisce la specie ospitata  
   IF NEW.Locale NOT IN ( SELECT Locale 
                              FROM Animale )  THEN 
     SET @numeroAnimali = 0;
  -- Aggiornamento dell'attributo MaxNumeroAnimali del locale, poiché ospita una nuova specie     
     SELECT Larghezza, Lunghezza INTO _larghezza, _lunghezza
     FROM Locale 
     WHERE Codice = NEW.Locale;
     UPDATE Locale
     SET MaxNumeroAnimali =  CalcolaCapienzaLocale(_specie, _lunghezza, _larghezza)
     WHERE Codice = NEW.Locale;
     
-- Controllo se l'animale inserito nel locale è della stessa specie degli animali attualmente ospitati      
  ELSEIF _specie NOT LIKE ( SELECT R.Specie
						     FROM Razza R NATURAL JOIN Animale A
                             WHERE A.Locale = NEW.Locale
                             LIMIT 1 ) THEN
	 SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'Animale di una specie diversa da quella ospitata nel locale';
     
  ELSE 
     SET @numeroAnimali = ( SELECT count(*) 
							FROM Animale A 
                            WHERE A.Locale = NEW.Locale );

  END IF;
  
  IF @numeroAnimali = ( SELECT L.MaxNumeroAnimali
                        FROM Locale L   
                        WHERE L.Codice = NEW.Locale ) THEN
	 SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'Numero massimo di animali ospitabili superato';
  END IF;
 END IF; 
END;
;;
DELIMITER ;


-- ----------------------------
--  Table structure for `RECINTO`
-- ----------------------------
DROP TABLE IF EXISTS `Recinto`;
CREATE TABLE `Recinto` (
  `CodiceRecinto` int(11) NOT NULL AUTO_INCREMENT,
  `Agriturismo` char(50) NOT NULL,
  PRIMARY KEY (CodiceRecinto),
  CONSTRAINT `FK_Recinto_Agriturismo` FOREIGN KEY (Agriturismo)
	REFERENCES Agriturismo(Nome)
	ON UPDATE CASCADE
	ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `RECINZIONE FISSA`
-- ----------------------------
DROP TABLE IF EXISTS `RecinzioneFissa`;
CREATE TABLE `RecinzioneFissa` (
  `Lat1` double NOT NULL,
  `Long1` double NOT NULL,
  `Lat2` double NOT NULL,
  `Long2` double NOT NULL,
  `Recinto` int(11) NOT NULL,
  PRIMARY KEY (Lat1, Long1, Lat2, Long2),
  CONSTRAINT `FK_RecinzioneFissa_Recinto` FOREIGN KEY (Recinto)
	REFERENCES Recinto(CodiceRecinto)
	ON UPDATE CASCADE
	ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ZONA DI PASCOLO`
-- ----------------------------
DROP TABLE IF EXISTS `ZonaDiPascolo`;
CREATE TABLE `ZonaDiPascolo` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Recinto` int(11) NOT NULL,
  PRIMARY KEY (Codice, Recinto),
  CONSTRAINT `FK_ZonaDiPascolo_Recinto` FOREIGN KEY (Recinto)
    REFERENCES Recinto(CodiceRecinto)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `RECINZIONE`
-- ----------------------------
DROP TABLE IF EXISTS `Recinzione`;
CREATE TABLE `Recinzione` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Lat1` double NOT NULL,
  `Long1` double NOT NULL,
  `Lat2` double NOT NULL,
  `Long2` double NOT NULL,
  PRIMARY KEY (Codice)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `DELIMITATA DA`
-- ----------------------------
DROP TABLE IF EXISTS `DelimitataDa`;
CREATE TABLE `DelimitataDa` (
  `Recinto` int(11) NOT NULL,
  `ZonaPascolo` int(11) NOT NULL,
  `Recinzione` int(11) NOT NULL,
  PRIMARY KEY (Recinto, ZonaPascolo, Recinzione),
  CONSTRAINT `FK_DelimitataDa_ZonaDiPascolo` FOREIGN KEY (ZonaPascolo, Recinto)
    REFERENCES ZonaDiPascolo(Codice, Recinto)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_DelimitataDa_Recinzione` FOREIGN KEY (Recinzione)
    REFERENCES Recinzione(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ATTIVITA PASCOLO`
-- ----------------------------
DROP TABLE IF EXISTS `AttivitaPascolo`;
CREATE TABLE `AttivitaPascolo` (
  `Data` date NOT NULL,
  `OraInizio` time NOT NULL,
  `Recinto` int(11) NOT NULL,
  `ZonaPascolo` int(11) NOT NULL,
  `OraFine`time NOT NULL,
  PRIMARY KEY (Data, OraInizio, Recinto, ZonaPascolo),
  CONSTRAINT `FK_AttivitaPascolo_ZonaDiPascolo` FOREIGN KEY (ZonaPascolo, Recinto)
    REFERENCES ZonaDiPascolo(Codice, Recinto)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- -------------------------------------------------------
-- IMPEDIRE ACCAVALLAMENTO DI ATTIVITA PASCOLO NELLA STESSA ZONA
-- -------------------------------------------------------
DROP TRIGGER IF EXISTS `checkAttivitaPascolo`;
DELIMITER ;;
CREATE TRIGGER `checkAttivitaPascolo` 
BEFORE INSERT ON AttivitaPascolo 
FOR EACH ROW 
BEGIN
  
  IF EXISTS (SELECT *
	         FROM AttivitaPascolo
             WHERE Data = NEW.Data
               AND Recinto = NEW.Recinto
               AND ZonaPascolo = NEW.ZonaPascolo
               AND OraInizio < NEW.OraInizio
               AND (OraFine IS NULL 
				    OR OraFine > New.OraInizio) )
     THEN
     SIGNAL SQLSTATE '45000'
	 SET MESSAGE_TEXT = 'Zona di pascolo occupata';
  END IF;
END;
;;
DELIMITER ;


-- ----------------------------
--  Table structure for `USCITA PASCOLO`
-- ----------------------------
DROP TABLE IF EXISTS `UscitaPascolo`;
CREATE TABLE `UscitaPascolo` (
  `Animale` int(11) NOT NULL,
  `Data` date NOT NULL,
  `OraInizio` time NOT NULL,
  `Recinto` int(11) NOT NULL,
  `ZonaPascolo` int(11) NOT NULL,
  `OraRientro`time DEFAULT NULL,
  PRIMARY KEY (Animale, Data, OraInizio, Recinto, ZonaPascolo),
  CONSTRAINT `FK_UscitaPascolo_Animale` FOREIGN KEY (Animale)
    REFERENCES Animale(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_UscitaPascolo_AttivitaPascolo` FOREIGN KEY (Data, OraInizio, Recinto, ZonaPascolo)
    REFERENCES AttivitaPascolo(Data, OraInizio, Recinto, ZonaPascolo)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- ---------------------------------------
-- CONTROLLO SUL LOCALE DEGLI ANIMALI PARTECIPANTI AD UNA ATTIVITA DI PASCOLO
-- ----------------------------------------
DROP TRIGGER IF EXISTS `checkPascoloLocale`;
DELIMITER ;;
CREATE TRIGGER `checkPascoloLocale` 
BEFORE INSERT ON UscitaPascolo 
FOR EACH ROW 
BEGIN
  DECLARE _localeAnimale int(11) DEFAULT NULL;
  DECLARE _localePascolo int(11) DEFAULT NULL;
  DECLARE _numeroPartecipanti int(11) DEFAULT 0;
  
  SELECT COUNT(*) INTO _numeroPartecipanti
  FROM UscitaPascolo UP
  WHERE UP.Data = NEW.Data
    AND UP.OraInizio = NEW.OraInizio
    AND UP.Recinto = NEW.Recinto
    AND UP.ZonaPascolo = NEW.ZonaPAscolo;
    
  IF _numeroPartecipanti > 0 THEN
  
     SELECT A.Locale INTO _localeAnimale
     FROM Animale A
     WHERE A.Codice = NEW.Animale;
     
     SELECT A.Locale INTO _localePascolo
     FROM UscitaPascolo U 
          INNER JOIN
          Animale A ON U.Animale = A.Codice
     WHERE U.Data = NEW.Data
       AND U.OraInizio = NEW.OraInizio
       AND U.Recinto = NEW.Recinto
       AND U.ZonaPascolo = NEW.ZonaPAscolo
	 LIMIT 1;  -- ne basta uno poichè sono tutti dello stesso locale
     
     IF _localePascolo <> _localeAnimale THEN
	   SIGNAL SQLSTATE '45000'
       SET MESSAGE_TEXT = 'Animale di un locale diverso da quello attualmente al pascolo';
     END IF;
     
  END IF;
   
END;
;;
DELIMITER ;


-- ----------------------------
--  Table structure for `POSIZIONE ANIMALE`
-- ----------------------------
DROP TABLE IF EXISTS `PosizioneAnimale`;
CREATE TABLE `PosizioneAnimale` (
  `Animale` int(11) NOT NULL,
  `Data` date NOT NULL,
  `Ora` time NOT NULL,
  `Latitudine` double NOT NULL,
  `Longitudine` double NOT NULL,
  PRIMARY KEY (Animale, Data, Ora),
  CONSTRAINT FK_PosizioneAnimale_Animale FOREIGN KEY (Animale)
    REFERENCES Animale(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `FORNITORE`
-- ----------------------------
DROP TABLE IF EXISTS `Fornitore`;
CREATE TABLE `Fornitore` (
  `PartitaIva` int(11) NOT NULL,
  `Nome` char(50) NOT NULL,
  `RagioneSociale` char(50) NOT NULL,
  `Citta` char(50) NOT NULL,
  `Via` char(50) NOT NULL,
  `NumeroCivico` int(11) NOT NULL,
  PRIMARY KEY (PartitaIva),
  CONSTRAINT `FK_Fornitore_Indirizzo` FOREIGN KEY (Citta, Via, NumeroCivico)
    REFERENCES Indirizzo(Citta, Via, NumeroCivico)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ANIMALE ACQUISTATO`
-- ----------------------------
DROP TABLE IF EXISTS `AnimaleAcquistato`;
CREATE TABLE `AnimaleAcquistato` (
  `Codice` int(11) NOT NULL,
  `DataNascita` date DEFAULT NULL,  -- sono nullabili poiché sono info appartenenti a terze parti, dunque l'acquisizione di tali informazioni potrebbe avvenire dopo un certo ritardo
  `IdPadre` char(50) DEFAULT NULL,
  `IdMadre` char(50) DEFAULT NULL,
  `Fornitore` int(11) NOT NULL,
  `DataArrivo` date DEFAULT NULL,
  `DataAcquisto` date NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_AnimaleAcquistato_Animale` FOREIGN KEY (Codice)
    REFERENCES Animale(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_AnimaleAcquistato_Fornitore` FOREIGN KEY (Fornitore)
    REFERENCES Fornitore(PartitaIva)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `VETERINARIO`
-- ----------------------------
DROP TABLE IF EXISTS `Veterinario`;
CREATE TABLE `Veterinario` (
  `Codice` int(11) NOT NULL,
  `Nome` char(50) NOT NULL,
  `Cognome` char(50) NOT NULL,
  PRIMARY KEY (Codice)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `RIPRODUZIONE`
-- ----------------------------
DROP TABLE IF EXISTS `Riproduzione`;
CREATE TABLE `Riproduzione` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Data` date NOT NULL,
  `Ora` time NOT NULL,
  `Esito` bool DEFAULT NULL,
  `Padre` int(11) DEFAULT NULL, -- sono nullabili perchè altrimenti se dovessimo mettere la fk con "on delete cascade", nel caso in cui muoia un genitore (delete) dovremmo cancellare pure le sue riproduzioni
  `Madre` int(11) DEFAULT NULL, -- invece mettendoli nullabili, possiamo mettere la fk "on delete set null" e quindi preservare la riproduzione e la gestazione di un animale figlio
  `Veterinario` int(11) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Riproduzione_Veterinario` FOREIGN KEY (Veterinario)
    REFERENCES Veterinario(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  CONSTRAINT `FK_Riproduzione_AnimalePadre` FOREIGN KEY (Padre)
    REFERENCES Animale(Codice)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT `FK_Riproduzione_AnimaleMadre` FOREIGN KEY (Madre)
    REFERENCES Animale(Codice)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `GESTAZIONE`
-- ----------------------------
DROP TABLE IF EXISTS `Gestazione`;
CREATE TABLE `Gestazione` (
  `CodiceRiproduzione` int(11) NOT NULL,
  `DataFine` date DEFAULT NULL,
  `Veterinario` int(11) NOT NULL,
  PRIMARY KEY (CodiceRiproduzione),
  CONSTRAINT `FK_Gestazione_Riproduzione` FOREIGN KEY (CodiceRiproduzione)
    REFERENCES Riproduzione(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  CONSTRAINT `FK_Gestazione_Veterinario` FOREIGN KEY (Veterinario)
    REFERENCES Veterinario(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `COMPLICANZA`
-- ----------------------------
DROP TABLE IF EXISTS `Complicanza`;
CREATE TABLE `Complicanza` (
  `CodiceRiproduzione` int(11) NOT NULL,
  `Data` date NOT NULL,
  `Ora` time NOT NULL,
  `Nome` char(50) NOT NULL,
  PRIMARY KEY (CodiceRiproduzione, Data, Ora),
  CONSTRAINT `FK_Complicanza_Gestazione` FOREIGN KEY (CodiceRiproduzione)
    REFERENCES Gestazione(CodiceRiproduzione)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ANIMALE NATO`
-- ----------------------------
DROP TABLE IF EXISTS `AnimaleNato`;
CREATE TABLE `AnimaleNato` (
  `Codice` int(11) NOT NULL,
  `CodiceRiproduzione` int(11) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_AnimaleNato_Animale` FOREIGN KEY (Codice)
    REFERENCES Animale(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_AnimaleNato_Gestazione` FOREIGN KEY (CodiceRiproduzione)
    REFERENCES Gestazione(CodiceRiproduzione)
    ON UPDATE CASCADE 
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `CONTROLLO PROGRAMMATO`
-- ----------------------------
DROP TABLE IF EXISTS `ControlloProgrammato`;
CREATE TABLE `ControlloProgrammato` (
  `CodiceRiproduzione` int(11) NOT NULL,
  `Data` date NOT NULL,
  PRIMARY KEY (CodiceRiproduzione, Data),
  CONSTRAINT `FK_ControlloProgrammato_Gestazione` FOREIGN KEY (CodiceRiproduzione)
    REFERENCES Gestazione(CodiceRiproduzione)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `TERAPIA`
-- ----------------------------
DROP TABLE IF EXISTS `Terapia`;
CREATE TABLE `Terapia` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `DataInizio` date NOT NULL,
  `DataFine` date NOT NULL,
  `Esito` bool DEFAULT NULL,                -- 0:positivo 1:negativo
  PRIMARY KEY (Codice)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- ---------------------
-- TRIGGER INSERIMENTO IN QUARANTENA
-- ---------------------
DROP TRIGGER IF EXISTS `NecessitaQuarantena`;
DELIMITER $$
CREATE TRIGGER `NecessitaQuarantena`
AFTER UPDATE ON Terapia
FOR EACH ROW
BEGIN
DECLARE _animaleQuarantena INT(11) DEFAULT NULL;
 
  IF( OLD.Esito IS NULL AND NEW.Esito = 1) THEN
	SELECT P.Animale INTO _animaleQuarantena
	FROM Patologia P
	WHERE P.CodiceTerapia = NEW.Codice
      	AND EXISTS (
                  	SELECT T.Codice
                  	FROM Patologia P2
                       	INNER JOIN
                       	Terapia T ON P2.CodiceTerapia = T.Codice
                  	WHERE P2.Animale = P.Animale
                        	AND P2.Nome = P.Nome
                        	AND T.Esito = 1
                        	AND T.DataFine <= NEW.DataInizio
                        	AND T.Codice <> NEW.Codice
                        	AND NOT EXISTS
   								 (
   								 SELECT T2.Codice
   								 FROM Patologia P3
   									  INNER JOIN
                                     	Terapia T2 ON P3.CodiceTerapia = T2.Codice
   								 WHERE P3.Nome = P2.Nome
   									   AND P3.Animale = P.Animale
                                      	AND T2.Esito = 0
                                      	AND T2.DataFine BETWEEN T.DataFine AND NEW.DataInizio
                                      	AND T2.Codice <> T.Codice
                                      	AND T2.Codice <> NEW.Codice
   								 )
   				  );
	IF(_animaleQuarantena IS NOT NULL) THEN
  	INSERT INTO Quarantena(Animale, DataInizio, OraInizio, DataFine, OraFine)
  	VALUES(_animaleQuarantena, CURRENT_DATE, CURRENT_TIME, NULL, NULL);
	END IF;
  END IF;
END $$
DELIMITER ;


-- ----------------------------
--  Table structure for `CONTROLLO EFFETTUATO`
-- ----------------------------
DROP TABLE IF EXISTS `ControlloEffettuato`;
CREATE TABLE `ControlloEffettuato` (
  `CodiceRiproduzione` int(11) NOT NULL,
  `DataProgrammata` date NOT NULL,
  `Data` date NOT NULL,
  `Esito` bool DEFAULT 0,                   -- 0:positivo 1:negativo
  `Veterinario` int(11) NOT NULL,
  `CodiceTerapia` int(11) DEFAULT NULL,
  PRIMARY KEY (CodiceRiproduzione, DataProgrammata),
  CONSTRAINT `FK_ControlloEffettuato_ControlloProgrammato` FOREIGN KEY (CodiceRiproduzione, DataProgrammata)
    REFERENCES ControlloProgrammato(CodiceRiproduzione, Data)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_ControlloEffettuato_Veterinario` FOREIGN KEY (Veterinario)
    REFERENCES Veterinario(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  CONSTRAINT `FK_ControlloEffettuato_Terapia` FOREIGN KEY (CodiceTerapia)
    REFERENCES Terapia(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `PROCEDURA ESAME`
-- ----------------------------
DROP TABLE IF EXISTS `ProceduraEsame`;
CREATE TABLE `ProceduraEsame` (
  `NomeEsame` char(50) NOT NULL,
  `Macchinario` char(50) DEFAULT NULL,
  `Procedura` text NOT NULL,
  PRIMARY KEY (NomeEsame)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ESAME DIAGNOSTICO`
-- ----------------------------
DROP TABLE IF EXISTS `EsameDiagnostico`;
CREATE TABLE `EsameDiagnostico` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `NomeEsame` char(50) NOT NULL,
  `Data` date NOT NULL,
  `CodiceRiproduzione` int(11) NOT NULL,
  `DataProgrammata` date NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_EsameDiagnostico_ControlloEffettuato` FOREIGN KEY (CodiceRiproduzione, DataProgrammata)
    REFERENCES ControlloEffettuato(CodiceRiproduzione, DataProgrammata)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_EsameDiagnostico_ProceduraEsame` FOREIGN KEY (NomeEsame)
    REFERENCES ProceduraEsame(NomeEsame)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `VISITA DI CONTROLLO`
-- ----------------------------
DROP TABLE IF EXISTS `VisitaDiControllo`;
CREATE TABLE `VisitaDiControllo` (
  `Animale` int(11) NOT NULL,
  `Data` date NOT NULL,
  `Ora` time NOT NULL,
  `MassaMagra` double NOT NULL,
  `MassaGrassa` double NOT NULL,
  `Veterinario` int NOT NULL,
  PRIMARY KEY (Animale, Data, Ora),
  CONSTRAINT `FK_VisitaDiControllo_Animale` FOREIGN KEY (Animale)
	REFERENCES Animale(Codice)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
  CONSTRAINT `FK_VisitaDiControllo_Veterinario` FOREIGN KEY (Veterinario)
	REFERENCES Veterinario(Codice)
	ON UPDATE CASCADE
	ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `INDICATORE OGGETTIVO`
-- ----------------------------
DROP TABLE IF EXISTS `IndicatoreOggettivo`;
CREATE TABLE `IndicatoreOggettivo` (
  `Nome` char(50) NOT NULL,
  `Animale` int(11) NOT NULL,
  `DataVisita` date NOT NULL,
  `OraVisita` time NOT NULL,
  PRIMARY KEY (Nome, Animale, DataVisita, OraVisita),
  CONSTRAINT `FK_IndicatoreOggettivo_VisitaDiControllo` FOREIGN KEY (Animale, DataVisita, OraVisita)
    REFERENCES VisitaDiControllo(Animale, Data, Ora)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `PARAMETRO`
-- ----------------------------
DROP TABLE IF EXISTS `Parametro`;
CREATE TABLE `Parametro` (
  `Nome` char(50) NOT NULL,
  PRIMARY KEY (Nome)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `DETERMINATO DA`
-- ----------------------------
DROP TABLE IF EXISTS `DeterminatoDa`;
CREATE TABLE `DeterminatoDa` (
  `Parametro` char(50) NOT NULL,
  `IndicatoreOggettivo` char(50) NOT NULL,
  `Animale` int(11) NOT NULL,
  `DataVisita` date NOT NULL,
  `OraVisita` time NOT NULL,
  `Valore` double NOT NULL,
  PRIMARY KEY (Parametro, IndicatoreOggettivo, Animale, DataVisita, OraVisita),
  CONSTRAINT `FK_DeterminatoDa_Parametro` FOREIGN KEY (Parametro)
    REFERENCES Parametro(Nome)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,
  CONSTRAINT `FK_DeterminatoDa_IndicatoreOggettivo` FOREIGN KEY (IndicatoreOggettivo, Animale, DataVisita, OraVisita)
    REFERENCES IndicatoreOggettivo(Nome, Animale, DataVisita, OraVisita)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `DISTURBO COMPORTAMENTALE`
-- ----------------------------
DROP TABLE IF EXISTS `DisturboComportamentale`;
CREATE TABLE `DisturboComportamentale` (
  `Nome` char(50) NOT NULL,
  `Animale` int(11) NOT NULL,
  `DataVisita` date NOT NULL,
  `OraVisita` time NOT NULL,
  `Entita` char(50) NOT NULL,
  PRIMARY KEY (Nome, Animale, DataVisita, OraVisita),
  CONSTRAINT `FK_DisturboComportamentale_VisitaDiControllo` FOREIGN KEY (Animale, DataVisita, OraVisita)
	REFERENCES VisitaDiControllo(Animale, Data, Ora)
	ON UPDATE CASCADE
	ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `LESIONE`
-- ----------------------------
DROP TABLE IF EXISTS `Lesione`;
CREATE TABLE `Lesione` ( 
  `Tipologia` char(50) NOT NULL,
  `ParteCorpo` char(50) NOT NULL, 
  `Animale` int(11) NOT NULL, 
  `DataVisita` date NOT NULL, 
  `OraVisita` time NOT NULL,
  `Entita` char(50) NOT NULL,
  PRIMARY KEY (Tipologia, ParteCorpo, Animale, DataVisita, OraVisita),
  CONSTRAINT `FK_Lesione_VisitaDiControllo` FOREIGN KEY (Animale, DataVisita, OraVisita)
    REFERENCES VisitaDiControllo(Animale, Data, Ora)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `STATO DI SALUTE`
-- ----------------------------
DROP TABLE IF EXISTS `StatoDiSalute`;
CREATE TABLE `StatoDiSalute` (
  `Animale` int(11) NOT NULL, 
  `DataVisita` date NOT NULL, 
  `OraVisita` time NOT NULL,
  `Vigilanza` int(11) DEFAULT NULL, 
  `Deambulazione` int(11) DEFAULT NULL, 
  `Respirazione` int(11) DEFAULT NULL, 
  `Idratazione` int(11) DEFAULT NULL, 
  `LucentezzaPelo` int(11) DEFAULT NULL,
  PRIMARY KEY (Animale, DataVisita, OraVisita),
  CONSTRAINT `FK_StatoDiSalute_VisitaDiControllo` FOREIGN KEY (Animale, DataVisita, OraVisita)
    REFERENCES VisitaDiControllo(Animale, Data, Ora)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `PATOLOGIA`
-- ----------------------------
DROP TABLE IF EXISTS `Patologia`;
CREATE TABLE `Patologia` (
  `Nome` char(50) NOT NULL,
  `Animale` int(11) NOT NULL,
  `DataVisita` date NOT NULL,
  `OraVisita` time NOT NULL,
  `CodiceTerapia` int(11) DEFAULT NULL,
  PRIMARY KEY (Nome, Animale, DataVisita, OraVisita),
  CONSTRAINT `FK_Patologia_VisitaDiControllo` FOREIGN KEY (Animale, DataVisita, OraVisita)
	REFERENCES VisitaDiControllo(Animale, Data, Ora)
	ON UPDATE CASCADE
	ON DELETE CASCADE,
  CONSTRAINT `FK_Patologia_Terapia` FOREIGN KEY (CodiceTerapia)
	REFERENCES Terapia(Codice)
	ON UPDATE CASCADE
	ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `PERIODO FARMACO`
-- ----------------------------
DROP TABLE IF EXISTS `PeriodioFarmaco`;
CREATE TABLE `PeriodoFarmaco` (
  `CodiceTerapia` int(11) NOT NULL, 
  `Farmaco` char(50) NOT NULL, 
  `DataInizio` date NOT NULL,
  `DataFine` date NOT NULL, 
  `GiorniDiPausa` int(11) NOT NULL,
  `GiorniConsecutivi` int(11) NOT NULL,
  PRIMARY KEY (CodiceTerapia, Farmaco, DataInizio),
  CONSTRAINT `FK_PeriodoFarmaco_Terapia` FOREIGN KEY (CodiceTerapia)
    REFERENCES Terapia(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `SOMMINISTRAZIONE NON CONTINUATIVA`
-- ----------------------------
DROP TABLE IF EXISTS `SomministrazioneNonContinuativa`;
CREATE TABLE `SomministrazioneNonContinuativa` (
  `CodiceTerapia` int(11) NOT NULL, 
  `Farmaco` char(50) NOT NULL, 
  `DataInizio` date NOT NULL, 
  `NumeroGiornoConsecutivo` int(11) NOT NULL, 
  `Orario` time NOT NULL,
  `Dose` double NOT NULL,
  PRIMARY KEY (CodiceTerapia, Farmaco, DataInizio, NumeroGiornoConsecutivo, Orario),
  CONSTRAINT `FK_SomministrazioneNonContinuativa_PeriodoFarmaco` FOREIGN KEY (CodiceTerapia, Farmaco, DataInizio)
    REFERENCES PeriodoFarmaco(CodiceTerapia, Farmaco, DataInizio)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `SOMMINISTRAZIONE CONTINUATIVA`
-- ----------------------------
DROP TABLE IF EXISTS `SomministrazioneContinuativa`;
CREATE TABLE `SomministrazioneContinuativa` (
  `CodiceTerapia` int(11) NOT NULL, 
  `Farmaco` char(50) NOT NULL, 
  `DataInizio` date NOT NULL, 
  `Orario` time NOT NULL,
  `Dose` double NOT NULL,
  PRIMARY KEY (CodiceTerapia, Farmaco, DataInizio, Orario),
  CONSTRAINT `FK_SomministrazioneContinuativa_PeriodoFarmaco` FOREIGN KEY (CodiceTerapia, Farmaco, DataInizio)
    REFERENCES PeriodoFarmaco(CodiceTerapia, Farmaco, DataInizio)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `QUARANTENA`
-- ----------------------------
DROP TABLE IF EXISTS `Quarantena`;
CREATE TABLE `Quarantena` (
  `Animale` int(11) NOT NULL,
  `DataInizio` date NOT NULL,
  `OraInizio` time NOT NULL,
  `DataFine` date DEFAULT NULL,
  `OraFine` time DEFAULT NULL,
  PRIMARY KEY (Animale, DataInizio, OraInizio),
  CONSTRAINT `FK_Quarantena_Animale` FOREIGN KEY (Animale)
	REFERENCES Animale(Codice)
	ON UPDATE CASCADE
	ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `MUNGITRICE`
-- ----------------------------
DROP TABLE IF EXISTS `Mungitrice`;
CREATE TABLE `Mungitrice` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Marca` char(50) NOT NULL,
  `Modello` char(50) NOT NULL, 
  `Agriturismo` char(50) NOT NULL, 
  `Latitudine` double DEFAULT NULL, 
  `Longitudine` double DEFAULT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Mungitrice_Agriturismo` FOREIGN KEY (Agriturismo)
    REFERENCES Agriturismo(Nome)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `SILOS`
-- ----------------------------
DROP TABLE IF EXISTS `Silos`;
CREATE TABLE `Silos` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Capacita` double NOT NULL,
  `Agriturismo` char(50) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Silos_Agriturismo` FOREIGN KEY (Agriturismo)
	REFERENCES Agriturismo(Nome)
	ON UPDATE CASCADE
	ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `MUNGITURA`
-- ----------------------------
DROP TABLE IF EXISTS `Mungitura`;
CREATE TABLE `Mungitura` (
  `Animale` int(11) NOT NULL, 
  `Data` date NOT NULL, 
  `OraInizio` time NOT NULL,
  `OraFine` time NOT NULL, 
  `QuantitaLatte` double NOT NULL, 
  `Mungitrice` int(11) NOT NULL, 
  `Silos` int(11) NOT NULL, 
  `Grasso` double NOT NULL, 
  `Proteine` double NOT NULL, 
  `Lattosio` double NOT NULL,
  PRIMARY KEY (Animale, Data, OraInizio),
  CONSTRAINT `FK_Mungitura_Animale` FOREIGN KEY (Animale)
    REFERENCES Animale(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_Mungitura_Mungitrice` FOREIGN KEY (Mungitrice)
    REFERENCES Mungitrice(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  CONSTRAINT `FK_Mungitura_Silos` FOREIGN KEY (Silos)
    REFERENCES Silos(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
DELIMITER ;;
-- ---------------------------------------------------------------
-- CONTROLLO SE IL SILOS IN CUI DEPOSITO IL LATTE PROVENIENTE DA UNA MUNGITURA SIA ADATTO
-- -----------------------------------------------------------------
DROP TRIGGER IF EXISTS `checkMungitura`;
DELIMITER ;;
CREATE TRIGGER `checkMungitura` 
BEFORE INSERT ON Mungitura 
FOR EACH ROW 
BEGIN
  DECLARE _contenutoSilos double DEFAULT 0;
  DECLARE _capacitaSilos double DEFAULT 0;
  DECLARE _latteDepositato double DEFAULT 0;
  DECLARE _lattePrelevato double DEFAULT 0;
  DECLARE _lattosio double DEFAULT 0;
  DECLARE _grasso double DEFAULT 0;
  DECLARE _proteine double DEFAULT 0;
  
  SELECT SUM(M.QuantitaLatte) INTO _latteDepositato
  FROM Silos S
	   INNER JOIN
       Mungitura M ON S.Codice = M.Silos
  WHERE S.Codice = NEW.Silos;
  
  SELECT SUM(L.QuantitaLatteUsato) INTO _lattePrelevato
  FROM Silos S
	   INNER JOIN
       Lotto L ON S.Codice = L.Silos
  WHERE S.Codice = NEW.Silos;
  
  SELECT S.Capacita INTO _capacitaSilos
  FROM Silos S
  WHERE S.Codice = NEW.Silos;
  
  SET _contenutoSilos = (_latteDepositato - _lattePrelevato);
  
  IF NEW.QuantitaLatte > (_capacitaSilos - _contenutoSilos) THEN
	 SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'Il silos non può contenere tale quantità di latte';
  ELSEIF _contenutoSilos <> 0 THEN 
   -- se il silos ha un contenuto, confronta la composizione del latte appena munto con quello dell'ultimo latte depositato nel silos
      SELECT Lattosio, Grasso, Proteine INTO _lattosio, _grasso, _proteine
      FROM Mungitura M
      WHERE M.Silos = NEW.Silos		
        AND NOT EXISTS ( SELECT *
		                 FROM Mungitura M2
                         WHERE M2.Silos = M.Silos
						   AND M2.Data > M.Data
                           OR (M2.Data = M.Data AND M2.OraFine > M.OraFine)
					   );    
      
      IF (_lattosio <> NEW.Lattosio)
         OR (NEW.Grasso < _grasso - 0.5 AND NEW.Grasso > _grasso + 0.5) 
         OR (NEW.Proteine < _proteine - 0.5 AND NEW.Proteine > _proteine + 0.5)
	  THEN
	    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Il silos contiene un latte dalla composizione chimico-fisica troppo diversa';  
	  END IF;
      
  END IF;
END;
;;
DELIMITER ;


-- ----------------------------
--  Table structure for `LABORATORIO`
-- ----------------------------
DROP TABLE IF EXISTS `Laboratorio`;
CREATE TABLE `Laboratorio` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Agriturismo` char(50) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Laboratorio_Agriturismo` FOREIGN KEY (Agriturismo)
	REFERENCES Agriturismo(Nome)
    ON UPDATE CASCADE
	ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `CANTINA`
-- ----------------------------
DROP TABLE IF EXISTS `Cantina`;
CREATE TABLE `Cantina` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Agriturismo` char(50) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Cantina_Agriturismo` FOREIGN KEY (Agriturismo)
	REFERENCES Agriturismo(Nome)
    ON UPDATE CASCADE
	ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `DIPENDENTE`
-- ----------------------------
DROP TABLE IF EXISTS `Dipendente`;
CREATE TABLE `Dipendente` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Laboratorio` int(11) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Dipendente_Laboratorio` FOREIGN KEY (Laboratorio)
	REFERENCES Laboratorio(Codice)
	ON UPDATE CASCADE
	ON DELETE NO ACTION
   ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `TIPOLOGIA FORMAGGIO`
-- ----------------------------
DROP TABLE IF EXISTS `TipologiaFormaggio`;
CREATE TABLE `TipologiaFormaggio` (
  `Nome` char(50) NOT NULL,
  `TipoPasta` char(50) NOT NULL,
  `GradoDeperibilita` char(50) NOT NULL, -- Stabile, deperibile o semi-deperibile
  PRIMARY KEY (Nome)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `RICETTA TESTUALE`
-- ----------------------------
DROP TABLE IF EXISTS `RicettaTestuale`;
CREATE TABLE `RicettaTestuale` (
  `TipologiaFormaggio` char(50) NOT NULL,
  `ZonaOrigine` char(50) NOT NULL,
  `Grasso` double NOT NULL,
  `Proteine` double NOT NULL,
  `Lattosio` double NOT NULL,
  PRIMARY KEY (TipologiaFormaggio, ZonaOrigine),
  CONSTRAINT `FK_RicettaTestuale_TipologiaFormaggio` FOREIGN KEY (TipologiaFormaggio)
    REFERENCES TipologiaFormaggio(Nome)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `FASE TESTUALE`
-- ----------------------------
DROP TABLE IF EXISTS `FaseTestuale`;
CREATE TABLE `FaseTestuale` (
  `TipologiaFormaggio` char(50) NOT NULL,
  `OrigineRicetta` char(50) NOT NULL,
   `NumeroProgressivo` int(11) NOT NULL,
   `Durata` int(11) NOT NULL, 		-- espresso in minuti
   `TemperaturaLatte` double NOT NULL, 
   `TempoRiposo` int(11) NOT NULL,  -- espresso in minuti
   `TemperaturaAmbiente` double NOT NULL,
  PRIMARY KEY (TipologiaFormaggio, OrigineRicetta, NumeroProgressivo),
  CONSTRAINT `FK_FaseTestuale_RicettaTestuale` FOREIGN KEY (TipologiaFormaggio, OrigineRicetta)
    REFERENCES RicettaTestuale(TipologiaFormaggio, ZonaOrigine)
    ON UPDATE NO ACTION
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `LOTTO`
-- ----------------------------
DROP TABLE IF EXISTS `Lotto`;
CREATE TABLE `Lotto` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `TipologiaFormaggio` char(50) NOT NULL,
  `OrigineRicetta` char(50) NOT NULL,
  `DataProduzione` date DEFAULT NULL,   -- DataProduzione viene inserita alla fine del processo produttivo
  `DataScadenza` date DEFAULT NULL,		-- DataScadenza viene inserita alla fine del processo produttivo
  `QuantitaLatteUsato` double NOT NULL,
  `Silos` int(11) NOT NULL,
  `Laboratorio` int(11) NOT NULL,
  `Cantina` int(11) DEFAULT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Lotto_Cantina` FOREIGN KEY (Cantina)
	REFERENCES Cantina(Codice)
	ON UPDATE CASCADE
	ON DELETE SET NULL,
  CONSTRAINT `FK_Lotto_Laboratorio` FOREIGN KEY (Laboratorio)
	REFERENCES Laboratorio(Codice)
	ON UPDATE CASCADE
	ON DELETE NO ACTION,
  CONSTRAINT `FK_Lotto_Silos` FOREIGN KEY (Silos)
	REFERENCES Silos(Codice)
	ON UPDATE CASCADE
	ON DELETE NO ACTION,
  CONSTRAINT `FK_Lotto_RicettaTestuale` FOREIGN KEY (TipologiaFormaggio, OrigineRicetta)
    REFERENCES RicettaTestuale(TipologiaFormaggio, ZonaOrigine)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- -------------------------------------------------------------
-- CONTROLLO SE IL SILOS DA CUI PRELEVO HA ABBASTANZA LATTE PER LA PRODUZIONE DI TALE LOTTO
-- --------------------------------------------------------------
DROP TRIGGER IF EXISTS `checkLotto`;
DELIMITER ;;
CREATE TRIGGER `checkLotto` 
BEFORE INSERT ON Lotto
FOR EACH ROW 
BEGIN
  DECLARE _contenutoSilos double DEFAULT 0;
  DECLARE _latteDepositato double DEFAULT 0;
  DECLARE _lattePrelevato double DEFAULT 0;
  
  SELECT SUM(M.QuantitaLatte) INTO _latteDepositato
  FROM Silos S
	   INNER JOIN
       Mungitura M ON S.Codice = M.Silos
  WHERE S.Codice = NEW.Silos;
  
  SELECT SUM(L.QuantitaLatteUsato) INTO _lattePrelevato
  FROM Silos S
	   INNER JOIN
       Lotto L ON S.Codice = L.Silos
  WHERE S.Codice = NEW.Silos;
  
  SET _contenutoSilos = (_latteDepositato - _lattePrelevato);
  
  IF NEW.QuantitaLatteUsato > _contenutoSilos THEN
  	 SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'Il silos non contiene tale quantità di latte';
  END IF;
END;
;;
DELIMITER ;


-- ----------------------------
--  Table structure for `STAGIONATURA PREVISTA`
-- ----------------------------
DROP TABLE IF EXISTS `StagionaturaPrevista`;
CREATE TABLE `StagionaturaPrevista` (
  `TipologiaFormaggio` char(50) NOT NULL, 
  `OrigineRicetta` char(50) NOT NULL,
  `Temperatura` double NOT NULL, 
  `Umidita` double NOT NULL, 
  `Ventilazione` double NOT NULL, 
  `Giorni` int(11) NOT NULL,
  PRIMARY KEY (TipologiaFormaggio, OrigineRicetta),
  CONSTRAINT `FK_StagionaturaPrevista_RicettaTestuale` FOREIGN KEY (TipologiaFormaggio, OrigineRicetta)
    REFERENCES RicettaTestuale(TipologiaFormaggio, ZonaOrigine)
    ON UPDATE NO ACTION
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `FASE PRODUZIONE`
-- ----------------------------
DROP TABLE IF EXISTS `FaseProduzione`;
CREATE TABLE `FaseProduzione` (
  `Lotto` int(11) NOT NULL,
  `NumeroProgressivo` int(11) NOT NULL,
  `Durata` int(11) NOT NULL,
  `TemperaturaLatte` double NOT NULL,
  `TempoRiposo` int(11) NOT NULL,
  `TemperaturaAmbiente` double NOT NULL,
  PRIMARY KEY (Lotto, NumeroProgressivo),
  CONSTRAINT `FK_FaseProduzione_Lotto` FOREIGN KEY (Lotto)
    REFERENCES Lotto(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `UNITA DI PRODOTTO`
-- ----------------------------
DROP TABLE IF EXISTS `UnitaDiProdotto`;
CREATE TABLE `UnitaDiProdotto` (
  `Codice` int(11) NOT NULL,
  `Lotto` int(11) NOT NULL,
  `Peso` double NOT NULL,
  PRIMARY KEY (Codice, Lotto),
  CONSTRAINT `FK_UnitaDiProdotto_Lotto` FOREIGN KEY (Lotto)
    REFERENCES Lotto(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `SCAFFALE`
-- ----------------------------
DROP TABLE IF EXISTS `Scaffale`;
CREATE TABLE `Scaffale` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (Codice)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `POSIZIONE`
-- ----------------------------
DROP TABLE IF EXISTS `Posizione`;
CREATE TABLE `Posizione` (
  `Numero` int(11) NOT NULL,
  `Scaffale` int(11) NOT NULL,
  PRIMARY KEY (Numero, Scaffale),
  CONSTRAINT `FK_Posizione_Scaffale` FOREIGN KEY (Scaffale)
    REFERENCES Scaffale(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `STOCCAGGIO`
-- ----------------------------
DROP TABLE IF EXISTS `Stoccaggio`;
CREATE TABLE `Stoccaggio` (
  `Lotto` int(11) NOT NULL,
  `CodiceUnita` int(11) NOT NULL,
  `Scaffale` int(11) NOT NULL,
  `NumeroPosizione` int(11) NOT NULL,
  `DataInizio` date NOT NULL,
  `OraInizio` time(3) NOT NULL,
  `DataFine` date DEFAULT NULL,
  `OraFine` time(3) DEFAULT NULL,
  PRIMARY KEY (Lotto, CodiceUnita, Scaffale, NumeroPosizione),
  CONSTRAINT `FK_Stoccaggio_UnitaDiProdotto` FOREIGN KEY (CodiceUnita, Lotto)
    REFERENCES UnitaDiProdotto(Codice, Lotto)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_Stoccaggio_Posizione` FOREIGN KEY (NumeroPosizione, Scaffale)
    REFERENCES Posizione(Numero, Scaffale)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `MAGAZZINO`
-- ----------------------------
DROP TABLE IF EXISTS `Magazzino`;
CREATE TABLE `Magazzino` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Agriturismo` char(50) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Magazzino_Agriturismo` FOREIGN KEY (Agriturismo)
    REFERENCES Agriturismo(Nome)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ORGANIZZATO IN`
-- ----------------------------
DROP TABLE IF EXISTS `OrganizzatoIn`;
CREATE TABLE `OrganizzatoIn` (
  `Magazzino` int(11) NOT NULL,
  `Scaffale` int(11) NOT NULL,
  PRIMARY KEY (Magazzino, Scaffale),
  CONSTRAINT `FK_OrganizzatoIn_Magazzino` FOREIGN KEY (Magazzino)
    REFERENCES Magazzino(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  CONSTRAINT `FK_OrganizzatoIn_Scaffale` FOREIGN KEY (Scaffale)
    REFERENCES Scaffale(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ORGANIZZATA IN`
-- ----------------------------
DROP TABLE IF EXISTS `OrganizzataIn`;
CREATE TABLE `OrganizzataIn` (
  `Cantina` int(11) NOT NULL,
  `Scaffale` int(11) NOT NULL,
  PRIMARY KEY (Cantina, Scaffale),
  CONSTRAINT `FK_OrganizzataIn_Cantina` FOREIGN KEY (Cantina)
    REFERENCES Cantina(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  CONSTRAINT `FK_OrganizzataIn_Scaffale` FOREIGN KEY (Scaffale)
    REFERENCES Scaffale(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `PARAMETRI AMBIENTE`
-- ----------------------------
DROP TABLE IF EXISTS `ParametriAmbiente`;
CREATE TABLE `ParametriAmbiente` (
  `Cantina` int(11) NOT NULL,
  `Data` date NOT NULL,
  `Temperatura` double NOT NULL,
  `Umidita` double NOT NULL,
  `Ventilazione` double NOT NULL,
  PRIMARY KEY (Cantina, Data),
  CONSTRAINT `FK_ParametriAmbiente_Cantina` FOREIGN KEY (Cantina)
    REFERENCES Cantina(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `LETTO`
-- ----------------------------
DROP TABLE IF EXISTS `Letto`;
CREATE TABLE `Letto` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Piazze` int(11) NOT NULL,
  PRIMARY KEY (Codice)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `SEMPLICE`
-- ----------------------------
DROP TABLE IF EXISTS `Semplice`;
CREATE TABLE `Semplice` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Agriturismo` char(50) NOT NULL,
  `Tariffa` double NOT NULL,
  `Letto` int(11) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Semplice_Agriturismo` FOREIGN KEY (Agriturismo)
    REFERENCES Agriturismo(Nome)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_Semplice_Letto` FOREIGN KEY (Letto)
    REFERENCES Letto(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `SUITE`
-- ----------------------------
DROP TABLE IF EXISTS `Suite`;
CREATE TABLE `Suite` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Agriturismo` char(50) NOT NULL,
  `Tariffa` double NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Suite_Agriturismo` FOREIGN KEY (Agriturismo)
    REFERENCES Agriturismo(Nome)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ARREDO SUITE`
-- ----------------------------
DROP TABLE IF EXISTS `ArredoSuite`;
CREATE TABLE `ArredoSuite` (
  `Suite` int(11) NOT NULL,
  `Letto` int(11) NOT NULL,
  PRIMARY KEY (Suite, Letto),
  CONSTRAINT `FK_ArredoSuite_Suite` FOREIGN KEY (Suite)
    REFERENCES Suite(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_ArredoSuite_Letto` FOREIGN KEY (Letto)
    REFERENCES Letto(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `CLIENTE`
-- ----------------------------
DROP TABLE IF EXISTS `Cliente`;
CREATE TABLE `Cliente` (
  `CodiceMetodo` int(11) NOT NULL,
  `MetodoPagamento` char(50) NOT NULL,
  PRIMARY KEY (CodiceMetodo)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `DOCUMENTO`
-- ----------------------------
DROP TABLE IF EXISTS `Documento`;
CREATE TABLE `Documento` (
  `CodiceDocumento` char(50) NOT NULL,
  `Nome` char(50) NOT NULL,
  `Cognome` char(50) NOT NULL,
  PRIMARY KEY (CodiceDocumento)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ACCOUNT`
-- ----------------------------
DROP TABLE IF EXISTS `Account`;
CREATE TABLE `Account` (
  `Cliente` int(11) NOT NULL,
  `CodiceDocumento` char(50) NOT NULL,
  `Password` char(50) NOT NULL,
  `EMail` char(50) NOT NULL,
  `Citta` char(50) NOT NULL,
  `Via` char(50) NOT NULL,
  `NumeroCivico` int(11) NOT NULL,
  PRIMARY KEY (Cliente),
  CONSTRAINT `FK_Account_Cliente` FOREIGN KEY (Cliente)
    REFERENCES Cliente(CodiceMetodo)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_Account_Indirizzo` FOREIGN KEY (Citta, Via, NumeroCivico)
    REFERENCES Indirizzo(Citta, Via, NumeroCivico)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  CONSTRAINT `FK_Account_Documento` FOREIGN KEY (CodiceDocumento)
    REFERENCES Documento(CodiceDocumento)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `PRENOTAZIONE`
-- ----------------------------
DROP TABLE IF EXISTS `Prenotazione`;
CREATE TABLE `Prenotazione` (
  `Cliente` int(11) NOT NULL,
  `DataPrenotazione` date NOT NULL,
  `OraPrenotazione` time NOT NULL,
  `DataPartenza` date NOT NULL,
  `DataArrivo` date NOT NULL,
  PRIMARY KEY (Cliente, DataPrenotazione, OraPrenotazione),
  CONSTRAINT `FK_Prenotazione_Cliente` FOREIGN KEY (Cliente)
    REFERENCES Cliente(CodiceMetodo)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `PAGAMENTO`
-- ----------------------------
DROP TABLE IF EXISTS `Pagamento`;
CREATE TABLE `Pagamento` (
  `Data` date NOT NULL,
  `Ora` time NOT NULL,
  `Cliente` int(11) NOT NULL,
  `DataPrenotazione` date NOT NULL,
  `OraPrenotazione` time NOT NULL,
  `Metodo` char(50) NOT NULL,
  `CodiceCarta` int(11) DEFAULT NULL,   -- potrebbe pagare in contanti
  `Importo` double NOT NULL,
  PRIMARY KEY (Data, Ora, Cliente, DataPrenotazione, OraPrenotazione),
  CONSTRAINT `FK_Pagamento_Prenotazione` FOREIGN KEY (Cliente, DataPrenotazione, OraPrenotazione)
    REFERENCES Prenotazione(Cliente, DataPrenotazione, OraPrenotazione)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `RISERVAZIONE SEMPLICE`
-- ----------------------------
DROP TABLE IF EXISTS `RiservazioneSemplice`;
CREATE TABLE `RiservazioneSemplice` (
  `Semplice` int(11) NOT NULL,
  `Cliente` int(11) NOT NULL,
  `DataPrenotazione` date NOT NULL,
  `OraPrenotazione` time NOT NULL,
  PRIMARY KEY (Semplice, Cliente, DataPrenotazione, OraPrenotazione),
  CONSTRAINT `FK_RiservazioneSemplice_Prenotazione` FOREIGN KEY (Cliente, DataPrenotazione, OraPrenotazione)
    REFERENCES Prenotazione(Cliente, DataPrenotazione, OraPrenotazione)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_RiservazioneSemplice_Semplice` FOREIGN KEY (Semplice)
    REFERENCES Semplice(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `RISERVAZIONE SUITE`
-- ----------------------------
DROP TABLE IF EXISTS `RiservazioneSuite`;
CREATE TABLE `RiservazioneSuite` (
  `Suite` int(11) NOT NULL,
  `Cliente` int(11) NOT NULL,
  `DataPrenotazione` date NOT NULL,
  `OraPrenotazione` time NOT NULL,
  PRIMARY KEY (Suite, Cliente, DataPrenotazione, OraPrenotazione),
  CONSTRAINT `FK_RiservazioneSuite_Prenotazione` FOREIGN KEY (Cliente, DataPrenotazione, OraPrenotazione)
    REFERENCES Prenotazione(Cliente, DataPrenotazione, OraPrenotazione)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT `FK_RiservazioneSuite_Suite` FOREIGN KEY (Suite)
    REFERENCES Suite(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `SERVIZIO`
-- ----------------------------
DROP TABLE IF EXISTS `Servizio`;
CREATE TABLE `Servizio` (
  `Tipo` char(50) NOT NULL,
  `Costo` double NOT NULL,
  PRIMARY KEY (Tipo)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `EXTRA`
-- ----------------------------
DROP TABLE IF EXISTS `Extra`;
CREATE TABLE `Extra` (
  `Suite` int(11) NOT NULL,
  `DataInizio` date NOT NULL,
  `Servizio` char(50) NOT NULL,
  `DataFine` date NOT NULL,
  PRIMARY KEY (Suite, DataInizio, Servizio),
  CONSTRAINT `FK_Extra_Suite` FOREIGN KEY (Suite)
    REFERENCES Suite(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE, -- la FK_RiservazioneSuite_Suite impedisce gia di cancellare una suite se esiste una riservazione ad essa associata, dunque FK_Extra_Suite permette la delete solo se non esiste piu una riservazione di tale suite
  CONSTRAINT `FK_Extra_Servizio` FOREIGN KEY (Servizio)
    REFERENCES Servizio(Tipo)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `GUIDA`
-- ----------------------------
DROP TABLE IF EXISTS `Guida`;
CREATE TABLE `Guida` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Nome` char(50) NOT NULL,
  `Cognome` char(50) NOT NULL,
  PRIMARY KEY (Codice)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `ESCURSIONE`
-- ----------------------------
DROP TABLE IF EXISTS `Escursione`;
CREATE TABLE `Escursione` (
  `Codice` int(11) NOT NULL AUTO_INCREMENT,
  `Data` date NOT NULL,
  `OraInizio` time NOT NULL,
  `Guida` int(11) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Escursione_Guida` FOREIGN KEY (Guida)
    REFERENCES Guida(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `PRENOTAZIONE ESCURSIONE`
-- ----------------------------
DROP TABLE IF EXISTS `PrenotazioneEscursione`;
CREATE TABLE `PrenotazioneEscursione` (
  `Cliente` int(11) NOT NULL,
  `Escursione` int(11) NOT NULL,
  `Data` date NOT NULL,
  `Ora` time NOT NULL,
  PRIMARY KEY (Cliente, Escursione),
  CONSTRAINT `FK_PrenotazioneEscursione_Cliente` FOREIGN KEY (Cliente)
    REFERENCES Cliente(CodiceMetodo)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  CONSTRAINT `FK_PrenotazioneEscursione_Escursione` FOREIGN KEY (Escursione)
    REFERENCES Escursione(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- --------------------------------
-- CONSENTI PRENOTAZIONE ESCURSIONE
-- --------------------------------
DROP TRIGGER IF EXISTS `ConsentiPrenotazioneEscursione`;
DELIMITER $$
CREATE TRIGGER `ConsentiPrenotazioneEscursione`
BEFORE INSERT ON PrenotazioneEscursione
FOR EACH ROW
BEGIN
  DECLARE _dataEscursione DATE DEFAULT NULL;
  DECLARE _oraEscursione TIME DEFAULT NULL;
 
  SELECT E.Data, E.OraInizio
  INTO _dataEscursione, _oraEscursione
  FROM Escursione E
  WHERE E.Codice = NEW.Escursione;
 
  CASE
	WHEN (NEW.Data = _dataEscursione - INTERVAL 2 DAY
   	   AND NEW.Ora >= _oraEscursione) THEN
   		  SIGNAL SQLSTATE '45000'
   		  SET MESSAGE_TEXT = 'PRENOTAZIONE TARDIVA';

	WHEN (NEW.Data > _dataEscursione - INTERVAL 2 DAY) THEN
      	SIGNAL SQLSTATE '45000'
      	SET MESSAGE_TEXT = 'PRENOTAZIONE TARDIVA';
	
    ELSE 
      BEGIN    -- Empty block per la condizione di uscita
      END;
  END CASE;
END $$
DELIMITER ;

-- ----------------------------
--  Table structure for `AREA`
-- ----------------------------
DROP TABLE IF EXISTS `Area`;
CREATE TABLE `Area` (
  Codice int(11) NOT NULL AUTO_INCREMENT,
  Agriturismo char(50) NOT NULL,
  PRIMARY KEY (Codice),
  CONSTRAINT `FK_Area_Agriturismo` FOREIGN KEY (Agriturismo)
    REFERENCES Agriturismo(Nome)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- ----------------------------
--  Table structure for `SOSTA`
-- ----------------------------
DROP TABLE IF EXISTS `Sosta`;
CREATE TABLE `Sosta` (
  Escursione int(11) NOT NULL,
  OraArrivo time NOT NULL,
  Durata int(11) NOT NULL,     -- espressa in minuti
  Area int(11) NOT NULL,
  PRIMARY KEY (Escursione, OraArrivo),
  CONSTRAINT `FK_Sosta_Area` FOREIGN KEY (Area)
    REFERENCES Area(Codice)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  CONSTRAINT `FK_Sosta_Escursione` FOREIGN KEY (Escursione)
    REFERENCES Escursione(Codice)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;





-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                                                                               ||            OPERAZIONI           ||
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ------------------------------------------
-- OPERAZIONE 1 - Registrazione Nuovo Account
-- ------------------------------------------
DROP PROCEDURE IF EXISTS `InserimentoClienteRegistrato`;
DELIMITER $$
CREATE PROCEDURE InserimentoClienteRegistrato (IN _metodoPagamento CHAR(50),
                                           	IN _codiceMetodo INT(11),
                                           	IN _codiceDocumento CHAR(50),
                                           	IN _nome CHAR(50),
                                           	IN _cognome CHAR(50),
                                           	IN _eMail CHAR(50),
                                           	IN _password CHAR(50),
                                           	IN _citta CHAR(50),
                                           	IN _via CHAR(50),
                                           	IN _numCivico INT(11),
                                           	IN _cap INT(5))
BEGIN
  DECLARE control BOOL DEFAULT 0;
 
  SELECT 1
  INTO control
  FROM Indirizzo I
  WHERE I.Citta = _citta
    	AND I.Via = _via
    	AND I.NumeroCivico = _numCivico;
   	 
  IF control = 0 THEN
    INSERT INTO Indirizzo
  	VALUES (_citta, _via, _numCivico, _cap);
  END IF;

  SET control = 0;
 
  SELECT 1
  INTO control
  FROM Documento D
  WHERE D.CodiceDocumento = _codiceDocumento;

  IF control = 0 THEN
	INSERT INTO Documento
  	VALUES (_codiceDocumento, _nome, _cognome);
  END IF;
 
  INSERT INTO Cliente
  VALUES (_codiceMetodo, _metodoPagamento);
 
  INSERT INTO `Account`
  VALUES (_codiceMetodo, _codiceDocumento, _password, _eMail,
      	_citta, _via, _numCivico);
END $$
DELIMITER ;


-- -----------------------------------------------------------------------------
-- OPERAZIONE 2 - Stoccaggio in Magazzino
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `StoccaggioMagazzino`;
DELIMITER ;;
CREATE PROCEDURE `StoccaggioMagazzino`(IN _lotto int(11),
                                   	   IN _magazzino int(11))
BEGIN
  DECLARE _numeroUnita int(11) DEFAULT 0;
  DECLARE _tipologiaFormaggio char(50) DEFAULT '';
  DECLARE _origineRicetta char(50) DEFAULT '';
  DECLARE _scaffale int(11) DEFAULT NULL;
  DECLARE _totPosizioni int(11) DEFAULT NULL;
  DECLARE _posLibere int(11) DEFAULT NULL;
  DECLARE _cantina int(11) DEFAULT NULL;
  DECLARE _indicePosizione int(11) DEFAULT 1;
  DECLARE _ultimaOccupata int(11) DEFAULT 0;
  DECLARE finito bool DEFAULT 0;
  DECLARE _codiceUnita int(11) DEFAULT NULL;
  DECLARE _data date DEFAULT current_date();
  DECLARE _ora time(3) DEFAULT current_time(3);
  
-- cursore per le unità di prodotto del lotto che si vuole stoccare
  DECLARE `cursoreUnita` CURSOR FOR
    SELECT U.Codice
    FROM UnitaDiProdotto U
    WHERE U.Lotto = _lotto
    ORDER BY U.Codice;    
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;    
  
-- recupero informazioni relative al lotto che si intende stoccare  
  SELECT COUNT(*),
     	L.TipologiaFormaggio,
     	L.OrigineRicetta,
        L.Cantina
     	INTO
     	_numeroUnita,
     	_tipologiaFormaggio,
     	_origineRicetta,
        _cantina
  FROM UnitaDiProdotto UP
   	   INNER JOIN
   	   Lotto L ON UP.Lotto = L.Codice 
  WHERE L.Codice = _lotto;
 
 
  SELECT *
  INTO _scaffale,
   	   _totPosizioni,
   	   _posLibere
  FROM (
   	    (
	-- Scaffali su cui sono stoccati altri lotti, ma con posizioni libere sufficienti
         SELECT S.Scaffale,
   				D.TotPosizioni,
   				D.TotPosizioni - COUNT(*) AS PosizioniLibere
   		 FROM Stoccaggio S
   			  NATURAL JOIN
   			  (
   			   SELECT P.Scaffale, COUNT(*) AS TotPosizioni
   			   FROM OrganizzatoIn OI
   					NATURAL JOIN
   					Posizione P
   			   WHERE OI.Magazzino = _magazzino
   			   GROUP BY P.Scaffale
   			   HAVING COUNT(*) >= _numeroUnita  
   			   ) AS D
   		 WHERE S.DataFine IS NULL
		    AND NOT EXISTS ( -- Prendo solo gli scaffali su cui sono stoccati attualmente lotti dello stesso tipo di formaggio che vogliamo inserire
   				        	SELECT *
   				        	FROM Stoccaggio S2
   					         	 INNER JOIN
   								 Lotto L2 ON L2.Codice = S2.Lotto
   							WHERE S2.Scaffale = S.Scaffale
   					          	AND S2.DataFine IS NULL
   					          	AND (L2.TipologiaFormaggio <> _tipologiaFormaggio
                                     OR
                                     L2.OrigineRicetta <> _origineRicetta)
   				           )
   		  GROUP BY S.Scaffale
   		  HAVING D.TotPosizioni - COUNT(*) >= _numeroUnita
      	)
   	 UNION
      	(
	-- Scaffali attualmente vuoti
         SELECT OI.Scaffale,    
				COUNT(*) AS TotPosizioni,
				COUNT(*) AS PosizioniLibere
         FROM OrganizzatoIn OI
              NATURAL JOIN
              Posizione P
         WHERE OI.Magazzino = _magazzino
               AND 
                -- Scaffali su cui non è mai stato stoccato un lotto o su cui attualmente non è stoccato alcun lotto
               NOT EXISTS ( 
                           SELECT *
                           FROM Stoccaggio S
                           WHERE S.Scaffale = OI.Scaffale
							 AND S.DataFine IS NULL
                          )                   	
         GROUP BY OI.Scaffale
         HAVING COUNT(*) >= _numeroUnita
   	   )
  ) AS D2
-- Scelgo lo scaffale con meno posizioni libere
  ORDER BY PosizioniLibere, Scaffale
  LIMIT 1;


  IF _scaffale IS NULL 
    THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Nessuno scaffale disponibile nel magazzino';
  ELSEIF _cantina IS NOT NULL  
    THEN
  -- Nel caso in cui si stia spostando un lotto da una cantina ad un magazzino, aggiorno la data e l'ora di fine stagionatura
    UPDATE Stoccaggio
    SET DataFine = _data,
        OraFine = _ora
    WHERE Lotto = _lotto 
      AND DataFine IS NULL
      AND OraFine IS NULL
	  AND Scaffale IN (
					   SELECT O.Scaffale
                       FROM OrganizzataIn O
                       WHERE O.Cantina = _cantina
	                  );
  END IF;
  
  
  -- Controllo gli scaffali non totalmente vuoti
  IF _totPosizioni <> _posLibere THEN
    -- Trovo l'ultima posizione occupata sullo scaffale  
    SELECT S.NumeroPosizione INTO _ultimaOccupata
    FROM Stoccaggio S
    WHERE S.Scaffale = _scaffale
      AND S.DataFine IS NULL
      AND S.OraFine IS NULL
      
      AND NOT EXISTS ( -- considero solamente l'ultimo lotto stoccato sullo scaffale
					  SELECT *
                      FROM Stoccaggio S2
                      WHERE S2.Scaffale = S.Scaffale
                        AND S2.DataFine IS NULL
                        AND S2.OraFine IS NULL
                        AND S2.Lotto <> S.Lotto
                        AND (S2.DataInizio > S.DataInizio
                             OR 
                             S2.DataInizio = S.DataInizio AND S2.OraInizio > S.OraInizio)
				     )
    -- per la politica di stoccaggio scelta, l'ultima unità del lotto stoccata è quella con codice maggiore
	  AND S.CodiceUnita = (SELECT max(U.Codice)
                           FROM UnitaDiProdotto U
                           WHERE U.Lotto = S.Lotto);                           
 -- Se l'ultima posizione sullo scaffale è l’ultima su cui è avvenuto lo stoccaggio, oppure se lo scaffale è attualmente vuoto, la prima posizione libera è quella con indice uguale a 1 ...                         
    IF _ultimaOccupata <> _totPosizioni THEN
     -- ... altrimenti è quella successiva all'ultima posizione occupata
       SET _indicePosizione = _ultimaOccupata + 1;
    END IF;    
  END IF;
  
  
  OPEN cursoreUnita;  
  scan: LOOP
    FETCH cursoreUnita INTO _codiceUnita;
    IF finito = 1 THEN
      LEAVE scan;
	END IF;
    
    INSERT INTO Stoccaggio(Lotto, CodiceUnita, Scaffale, NumeroPosizione, DataInizio, OraInizio)
    VALUES (_lotto, _codiceUnita, _scaffale, _indicePosizione, _data, _ora);
        
    IF _indicePosizione = _totPosizioni THEN
      SET _indicePosizione = 1;
	ELSE 
      SET _indicePosizione = _indicePosizione + 1;
	END IF;
    
  END LOOP scan;
  CLOSE cursoreUnita;
    
END ;
;;
DELIMITER ;


-- ----------------------------------------------------------------------------------
-- OPERAZIONE 2.bis - Stoccaggio in Cantina
-- ----------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `StoccaggioCantina`;
DELIMITER ;;
CREATE PROCEDURE `StoccaggioCantina`(IN _lotto int(11),
                                   	 IN _cantina int(11))
BEGIN
  DECLARE _numeroUnita int(11) DEFAULT 0;
  DECLARE _tipologiaFormaggio char(50) DEFAULT '';
  DECLARE _origineRicetta char(50) DEFAULT '';
  DECLARE _scaffale int(11) DEFAULT NULL;
  DECLARE _totPosizioni int(11) DEFAULT NULL;
  DECLARE _posLibere int(11) DEFAULT NULL;
  DECLARE _indicePosizione int(11) DEFAULT 1;
  DECLARE _ultimaOccupata int(11) DEFAULT 0;
  DECLARE finito bool DEFAULT 0;
  DECLARE _codiceUnita int(11) DEFAULT NULL;
  DECLARE _data date DEFAULT current_date();
  DECLARE _ora time(3) DEFAULT current_time(3);
  
  DECLARE `cursoreUnita` CURSOR FOR
    SELECT U.Codice
    FROM UnitaDiProdotto U
    WHERE U.Lotto = _lotto
    ORDER BY U.Codice;    
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;    
  
  SELECT COUNT(*),
     	L.TipologiaFormaggio,
     	L.OrigineRicetta     	
        INTO
     	_numeroUnita,
     	_tipologiaFormaggio,
     	_origineRicetta
  FROM UnitaDiProdotto UP
   	   INNER JOIN 
   	   Lotto L ON UP.Lotto = L.Codice
  WHERE L.Codice = _lotto;
 
  SELECT *
  INTO _scaffale,
   	   _totPosizioni,
   	   _posLibere
  FROM (
   	    (
	-- Scaffali su cui sono stoccati altri lotti, ma con posizioni libere sufficienti
         SELECT S.Scaffale,
   				D.TotPosizioni,
   				D.TotPosizioni - COUNT(*) AS PosizioniLibere
   		 FROM Stoccaggio S
   			  NATURAL JOIN
   			  (
   			   SELECT P.Scaffale, COUNT(*) AS TotPosizioni
   			   FROM OrganizzataIn OI
   					NATURAL JOIN
   					Posizione P
   			   WHERE OI.Cantina = _cantina
   			   GROUP BY P.Scaffale
   			   HAVING COUNT(*) >= _numeroUnita  
   			   ) AS D
   		 WHERE S.DataFine IS NULL
		    AND NOT EXISTS ( -- Prendo solo gli scaffali su cui sono stoccati attualmente lotti dello stesso tipo di formaggio che vogliamo inserire
   				        	SELECT *
   				        	FROM Stoccaggio S2
   					         	 INNER JOIN
   								 Lotto L2 ON L2.Codice = S2.Lotto
   							WHERE S2.Scaffale = S.Scaffale
   					          	AND S2.DataFine IS NULL
   					          	AND (L2.TipologiaFormaggio <> _tipologiaFormaggio
                                      	OR L2.OrigineRicetta <> _origineRicetta)
   				           )
   		  GROUP BY S.Scaffale
   		  HAVING D.TotPosizioni - COUNT(*) >= _numeroUnita
      	)
   	 UNION
      	(
	-- Scaffali attualmente vuoti
         SELECT OI.Scaffale,    
				COUNT(*) AS TotPosizioni,
				COUNT(*) AS PosizioniLibere
         FROM OrganizzataIn OI
              NATURAL JOIN
              Posizione P
         WHERE OI.Cantina = _cantina
               AND (
                -- Scaffali su cui non è mai stato stoccato un lotto o su cui attualmente non è stoccato alcun lotto
                    NOT EXISTS ( 
                            	SELECT *
                            	FROM Stoccaggio S
                            	WHERE S.Scaffale = OI.Scaffale
                                  	AND S.DataFine IS NULL
                               )
                   	)
         	GROUP BY OI.Scaffale
         	HAVING COUNT(*) >= _numeroUnita
   	   )
  ) AS D2
  -- Scelgo lo scaffale con meno posizioni libere
  ORDER BY PosizioniLibere, Scaffale
  LIMIT 1;

  IF _scaffale IS NULL 
    THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Nessuno scaffale disponibile nella cantina';
  ELSE
  -- --------------------------------------------------------------------
  -- AGGIORNAMENTO RIDONDANZA dell'attributo Cantina nella tabella Lotto
  -- --------------------------------------------------------------------
    UPDATE Lotto
    SET Cantina = _cantina
    WHERE Codice = _lotto;
  END IF;
    
  -- Controllo gli scaffali non totalmente vuoti
  IF _totPosizioni <> _posLibere THEN
    -- Trovo l'ultima posizione occupata sullo scaffale  
    SELECT S.NumeroPosizione INTO _ultimaOccupata
    FROM Stoccaggio S
    WHERE S.Scaffale = _scaffale
      AND S.DataFine IS NULL
      AND S.OraFine IS NULL
      AND NOT EXISTS ( -- considero solamente l'ultimo lotto stoccato sullo scaffale
					  SELECT *
                      FROM Stoccaggio S2
                      WHERE S2.Scaffale = S.Scaffale
                        AND S2.DataFine IS NULL
                        AND S2.OraFine IS NULL
                        AND S2.Lotto <> S.Lotto
                        AND (S2.DataInizio > S.DataInizio
                             OR 
                             S2.DataInizio = S.DataInizio AND S2.OraInizio > S.OraInizio)
				     )
    -- per la politica di stoccaggio scelta, l'ultima unità del lotto stoccata è quella con codice maggiore
	  AND S.CodiceUnita = (SELECT max(U.Codice)
                           FROM UnitaDiProdotto U
                           WHERE U.Lotto = S.Lotto);                           
 -- Se l'ultima posizione sullo scaffale è l’ultima su cui è avvenuto lo stoccaggio, oppure se lo scaffale è attualmente vuoto, la prima posizione libera è quella con indice uguale a 1 ...                         
    IF _ultimaOccupata <> _totPosizioni THEN
     -- ... altrimenti è quella successiva all'ultima posizione occupata
       SET _indicePosizione = _ultimaOccupata + 1;
    END IF;    
  END IF;
  
  OPEN cursoreUnita;  
  scan: LOOP
    FETCH cursoreUnita INTO _codiceUnita;
    IF finito = 1 THEN
      LEAVE scan;
	END IF;
    
    INSERT INTO Stoccaggio(Lotto, CodiceUnita, Scaffale, NumeroPosizione, DataInizio, OraInizio)
    VALUES (_lotto, _codiceUnita, _scaffale, _indicePosizione, _data, _ora);
        
    IF _indicePosizione = _totPosizioni THEN
      SET _indicePosizione = 1;
	ELSE 
      SET _indicePosizione = _indicePosizione + 1;
	END IF;
    
  END LOOP scan;
  CLOSE cursoreUnita;
  
  
  END ;
;;
DELIMITER ;


-- --------------------------------------------------------
-- OPERAZIONE 3 - Controllo Fase Produttiva
-- --------------------------------------------------------
DROP PROCEDURE IF EXISTS `ScostamentoFaseProduzione`;
DELIMITER $$
CREATE PROCEDURE ScostamentoFaseProduzione ( IN _lotto INT(11),
   										     IN _numeroFase INT(11),
   										     OUT diffDurata_ INT(11),
   										     OUT diffTempLatte_ DOUBLE,
   										     OUT diffTempoRiposo_ INT(11),
   										     OUT diffTempAmbiente_ DOUBLE)
BEGIN
  SELECT (FP.Durata - FT.Durata),
		 (FP.TemperaturaLatte - FT.TemperaturaLatte),
     	 (FP.TempoRiposo - FT.TempoRiposo),
     	 (FP.TemperaturaAmbiente - FT.TemperaturaAmbiente)
  INTO diffDurata_, 
       diffTempLatte_,
   	   diffTempoRiposo_, 
       diffTempAmbiente_
   FROM FaseTestuale FT
   	    NATURAL JOIN
   	    Lotto L
   	    INNER JOIN
   	    FaseProduzione FP ON FP.Lotto = L.Codice AND FP.NumeroProgressivo = FT.NumeroProgressivo
  WHERE L.Codice = _lotto
    AND FT.NumeroProgressivo = _numeroFase;
END $$
DELIMITER ;


-- --------------------------------------------------
-- OPERAZIONE 4 - Rilevamento Rimanenza Pasto
-- --------------------------------------------------
DROP PROCEDURE IF EXISTS `RimanenzaPasto`;
DELIMITER ;;
CREATE PROCEDURE RimanenzaPasto(IN _dataPasto date,
                                IN _oraPasto time, 
                                IN _mangiatoia int(11),
                                OUT quantita_ double)
BEGIN
  SET quantita_ = NULL;  
  SELECT F.Quantita INTO quantita_
  FROM Foraggio F
  WHERE F.DataPasto = _dataPasto
	AND F.OraPasto = _oraPasto
    AND F.Mangiatoia = _mangiatoia
    AND NOT EXISTS (SELECT *
                    FROM Foraggio F2
                    WHERE F2.DataPasto = _dataPasto
					  AND F2.OraPasto = _oraPasto
                      AND F2.Mangiatoia = _mangiatoia
                      AND (F2.Data > F.Data  
					   OR (F2.Data = F.Data AND F2.Ora > F.Ora))
				    );
END;
;;
DELIMITER ;


-- -------------------------------------------------------------------------------------------------------------
-- OPERAZIONE 5 - Controllo Stagionatura
-- -------------------------------------------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `ControlloStagionatura`;
DELIMITER ;;
CREATE PROCEDURE ControlloStagionatura(IN _cantina int(11), IN _data date)
BEGIN
  CREATE TEMPORARY TABLE IF NOT EXISTS _ScostamentiStagionatura(
	`Lotto` int(11) NOT NULL,
	`DifferenzaTemperatura` double NOT NULL,
 	`DifferenzaUmidita` double NOT NULL,
    `DifferenzaVentilazione` double NOT NULL,
    PRIMARY KEY (Lotto)
	) ENGINE = InnoDB DEFAULT CHARSET = Latin1;
  
  TRUNCATE TABLE _ScostamentiStagionatura;
  
  INSERT INTO _ScostamentiStagionatura
  SELECT L.Codice AS Lotto, 
         (PA.Temperatura - SP.Temperatura) AS DifferenzaTemperatura, 
         (PA.Umidita - SP.Umidita) AS DifferenzaUmidita, 
         (PA.Ventilazione - SP.Ventilazione) AS DifferenzaVentilazione
  FROM Lotto L
       NATURAL JOIN
       StagionaturaPrevista SP 
       INNER JOIN
       ParametriAmbiente PA ON L.Cantina = PA.Cantina
  WHERE PA.Cantina = _cantina
    AND PA.Data = _data;
    
END;
;;
DELIMITER ;


-- ----------------------------------------------
-- OPERAZIONE 6 - Rilevamento Animali In Ritardo
-- ----------------------------------------------
DROP PROCEDURE IF EXISTS `RitardoRientroAnimali`;
DELIMITER $$
CREATE PROCEDURE RitardoRientroAnimali( IN _data DATE,
   									    IN _oraInizio TIME,
                                    	IN _recinto INT(11),
                                    	IN _zonaPascolo INT(11))
BEGIN                                    	 
  CREATE TEMPORARY TABLE IF NOT EXISTS _AnimaliInRitardo(
	`Animale` int(11) NOT NULL,
	`Ritardo` time NOT NULL,
	PRIMARY KEY (Animale)
	) ENGINE = InnoDB DEFAULT CHARSET = Latin1;
 
  TRUNCATE TABLE _AnimaliInRitardo;
 
  INSERT INTO _AnimaliInRitardo
  SELECT UP.Animale, TIMEDIFF(UP.OraRientro, AP.OraFine) AS Ritardo
  FROM AttivitaPascolo AP
   	NATURAL JOIN
   	UscitaPascolo UP
  WHERE AP.Data = _data
   	 AND AP.OraInizio = _oraInizio
    	AND AP.Recinto = _recinto
    	AND AP.ZonaPascolo = _zonaPascolo
   	 AND UP.OraRientro > AP.Orafine;
END $$
DELIMITER ;


-- -----------------------------------------------------------------------------
-- OPERAZIONE 7 - Disponibilità Stanze
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `StanzeLibere`;
DELIMITER ;;
CREATE PROCEDURE StanzeLibere (IN _dataPartenza date, IN _dataArrivo date, IN _agriturismo char(50))
BEGIN 
  CREATE TEMPORARY TABLE IF NOT EXISTS _DisponibilitaPeriodo(
	`TipoStanza` char(50) NOT NULL,
	`Codice` int(11) NOT NULL,
	PRIMARY KEY (TipoStanza, Codice)
	) ENGINE = InnoDB DEFAULT CHARSET = Latin1;
  TRUNCATE TABLE _DisponibilitaPeriodo;
  
  INSERT INTO _DisponibilitaPeriodo
  SELECT 'Semplice' AS TipoStanza, SE.Codice
  FROM Semplice SE
  WHERE SE.Agriturismo = _agriturismo
    AND SE.Codice NOT IN ( SELECT RSE.Semplice
						   FROM Prenotazione P
                                NATURAL JOIN
                                RiservazioneSemplice RSE
                           WHERE _dataArrivo BETWEEN P.DataArrivo AND P.DataPartenza 
                              OR _dataPartenza BETWEEN P.DataArrivo AND P.DataPartenza);
                              
  INSERT INTO _DisponibilitaPeriodo               
  SELECT 'Suite' AS TipoStanza, SU.Codice
  FROM Suite SU
  WHERE SU.Agriturismo = _agriturismo
    AND SU.Codice NOT IN ( SELECT RSU.Suite
						   FROM Prenotazione P
                                NATURAL JOIN
                                RiservazioneSuite RSU
                            WHERE _dataArrivo BETWEEN P.DataArrivo AND P.DataPartenza 
                              OR _dataPartenza BETWEEN P.DataArrivo AND P.DataPartenza);                           
END;
;; 
DELIMITER ;


-- --------------------------------------
-- OPERAZIONE 8 - Calcola Costo Soggiorno
-- --------------------------------------
DROP FUNCTION IF EXISTS `CostoSoggiorno`;
DELIMITER $$
CREATE FUNCTION CostoSoggiorno ( _dataPrenotazione DATE,
                             	_oraPrenotazione TIME,
                             	_codiceMetodoCliente INT(11))
RETURNS DOUBLE DETERMINISTIC
BEGIN
  DECLARE CostoTotale DOUBLE DEFAULT 0;

  SELECT P.DataArrivo, P.DataPartenza
  INTO @_dataArrivo, @_dataPartenza
  FROM Prenotazione P
  WHERE P.Cliente = _codiceMetodoCliente
    	AND P.DataPrenotazione = _dataPrenotazione
    	AND P.OraPrenotazione = _oraPrenotazione;
   	 
  SELECT SUM(S.Tariffa)*DATEDIFF(@_dataPartenza, @_dataArrivo)
  INTO @costoSemplice
  FROM RiservazioneSemplice RS
   	INNER JOIN
   	Semplice S ON S.Codice = RS.Semplice
  WHERE RS.Cliente = _codiceMetodoCliente
    	AND RS.DataPrenotazione = _dataPrenotazione
    	AND RS.OraPrenotazione = _oraPrenotazione;
        
  IF @costoSemplice IS NULL THEN
    SET @costoSemplice = 0;
  END IF;
 
  SELECT SUM(S.Tariffa)*DATEDIFF(@_dataPartenza, @_dataArrivo)
  INTO @costoSuite
  FROM RiservazioneSuite RS
   	INNER JOIN
   	Suite S ON S.Codice = RS.Suite
  WHERE RS.Cliente = _codiceMetodoCliente
    	AND RS.DataPrenotazione = _dataPrenotazione
    	AND RS.OraPrenotazione = _oraPrenotazione;
        
  IF @costoSuite IS NULL THEN
    SET @costoSuite = 0;
  END IF;
 
  SELECT SUM( (DATEDIFF(E.DataFine, E.DataInizio) + 1) * S.Costo)
  INTO @costoExtra
  FROM RiservazioneSuite RS
   	NATURAL JOIN
   	Extra E
   	INNER JOIN
   	Servizio S ON E.Servizio = S.Tipo
  WHERE RS.Cliente = _codiceMetodoCliente
    	AND RS.DataPrenotazione = _dataPrenotazione
    	AND RS.OraPrenotazione = _oraPrenotazione;

  IF @costoExtra IS NULL THEN
    SET @costoExtra = 0;
  END IF;
  
  SET CostoTotale = @costoSemplice + @costoSuite + @costoExtra; 	 

  RETURN (CostoTotale);
END $$
DELIMITER ;


-- --------------------------------------------------
-- Pagamento Caparra Utenti Non Registrati ON DEMAND
-- --------------------------------------------------
DROP PROCEDURE IF EXISTS `CaparraNoAccount`;
DELIMITER $$
CREATE PROCEDURE CaparraNoAccount(IN _codiceMetodoCliente INT(11),
   							   IN _dataPrenotazione DATE,
                              	IN _oraPrenotazione TIME)
BEGIN
  DECLARE importoCaparra DOUBLE DEFAULT 0;
  DECLARE metodoPagamento CHAR(50) DEFAULT '';
 
  SELECT C.MetodoPagamento
  INTO metodoPagamento
  FROM Prenotazione P
   	   INNER JOIN
   	   Cliente C ON P.Cliente = C.CodiceMetodo
  WHERE P.DataPrenotazione = _dataPrenotazione
   	 AND P.OraPrenotazione= _oraPrenotazione
    	AND P.Cliente = _codiceMetodoCliente;
   	 
  SELECT CostoSoggiorno(_dataPrenotazione,
   				 	    _oraPrenotazione,
                        _codiceMetodoCliente)
  INTO importoCaparra;
 
  INSERT INTO Pagamento
  VALUES (_dataPrenotazione, _oraPrenotazione, _codiceMetodoCliente,
   	   _dataPrenotazione, _oraPrenotazione,
      	metodoPagamento, _codiceMetodoCliente,
      	importoCaparra/2);  -- viene pagata la metà del costo totale delle stanze
   						   -- prenotate, per il periodo corrispondente, dagli
                          	-- utenti non registrati. Il metodo di pagamento è quello specificato
                          	-- al momento della prenotazione stessa
END $$
DELIMITER ;


-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                                                                               ||            ANALYTICS           ||
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--  ||     ANALYTICS 1: COMPORTAMENTO DEGLI ANIMALI     ||

DROP PROCEDURE IF EXISTS `ComportamentoAnimali`;
DELIMITER ;;
CREATE PROCEDURE ComportamentoAnimali(IN _data date,
                                      IN _oraInizio time,
                                      IN _recinto int(11),
                                      IN _zonaPascolo int(11))
BEGIN
-- Variabili per il conteggio delle posizioni di ogni quadrante
  DECLARE contaNE int(11) DEFAULT 0;
  DECLARE contaNW int(11) DEFAULT 0;
  DECLARE contaSE int(11) DEFAULT 0;
  DECLARE contaSW int(11) DEFAULT 0;
-- Variabili per il calcolo delle medie delle posizioni di ogni quadrante  
  DECLARE xNE double DEFAULT 0;
  DECLARE xNW double DEFAULT 0;
  DECLARE xSE double DEFAULT 0;
  DECLARE xSW double DEFAULT 0;
  DECLARE yNE double DEFAULT 0;
  DECLARE yNW double DEFAULT 0;
  DECLARE ySE double DEFAULT 0;
  DECLARE ySW double DEFAULT 0;  
-- Variabili per il calcolo delle assi che dividono i quadranti
  DECLARE xMax double DEFAULT 0;
  DECLARE yMax double DEFAULT 0;
  DECLARE xMin double DEFAULT 0;
  DECLARE yMin double DEFAULT 0;
-- Variabili degli assi che dividono i quadranti
  DECLARE xQ double DEFAULT 0;
  DECLARE yQ double DEFAULT 0;
-- Variabili delle posizioni degli animali
  DECLARE x double DEFAULT 0;
  DECLARE y double DEFAULT 0;
-- Variabile di uscita dal loop
  DECLARE finito bool DEFAULT 0;  
-- Cursore per le posizioni degli animali durante l'attività di pascolo in esame  
  DECLARE `cursoreGPS` CURSOR FOR
  SELECT PA.Latitudine, PA.Longitudine
  FROM PosizioneAnimale PA
       INNER JOIN
       UscitaPascolo UP ON PA.Animale = UP.Animale 
                          AND PA.Data = UP.Data
  WHERE UP.Data = _data
    AND UP.OraInizio = _oraInizio
    AND UP.Recinto = _recinto
    AND UP.ZonaPascolo = _zonaPascolo
    AND PA.Ora BETWEEN UP.OraInizio AND UP.OraRientro;
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET finito = 1;
  
  CREATE TEMPORARY TABLE IF NOT EXISTS `RankQuadranti`(
    `Quadrante` char(50) NOT NULL,          -- NE, NW, SE, SW
    `PosizioniRegistrate` int(11) NOT NULL, -- conteggio di quante posizioni sono state registrate nel quadrante
    `PosizioneMedia` char(100) NOT NULL,       -- concat di x,y medie delle posizioni nel quadrante
    PRIMARY KEY (Quadrante)
  ) ENGINE = InnoDB DEFAULT CHARSET = Latin1;
  TRUNCATE TABLE RankQuadranti;
  
-- Per dividere in quadranti una zona di pascolo, immagino di racchiudere l'area in un quadrato con vertici (xMax,yMax), (xMax,yMin), (xMin,yMax), (xMin,yMin)
-- e trovo le due rette che passano per i punti medi dei lati del quadrato immaginario
  SELECT IF(max(lat1) > max(lat2),   max(lat1),  max(lat2) ),
         IF(min(lat1) < min(lat2),   min(lat1),  min(lat2) ),  
         IF(max(long1) > max(long2), max(long1), max(long2)),
         IF(min(long1) < min(long2), min(long1), min(long2))
  INTO yMax, 
       yMin, 
       xMax, 
       xMin
  FROM DelimitataDa DD
       INNER JOIN
       Recinzione RM ON DD.Recinzione = RM.Codice
  WHERE DD.ZonaPascolo = _zonaPascolo
    AND DD.Recinto = _recinto;

  SET xQ = (xMin + xMax) / 2;  -- longitudine della prima retta che divide i quadranti
  SET yQ = (yMin + yMax) / 2;  -- latitudine della seconda retta che divide i quadranti
  
  OPEN cursoreGPS;
  scan: LOOP
    FETCH cursoreGPS INTO y, x;  -- latitudine, longitudine della posizione dell'animale al pascolo
    IF finito = 1 THEN
      LEAVE scan;
    END IF;    
    IF      x >= xQ  AND  y >= yQ  THEN
      SET contaNE = contaNE + 1;
      SET xNE = xNE + x;
      SET yNE = yNE + y;
	ELSEIF  x >= xQ  AND  y < yQ  THEN
      SET contaSE = contaSE + 1;
      SET xSE = xSE + x;
      SET ySE = ySE + y;
	ELSEIF  x < xQ  AND  y < yQ  THEN
      SET contaSW = contaSW + 1;
      SET xSW = xSW + x;
      SET ySW = ySW + y;
	ELSEIF  x < xQ  AND  y >= yQ  THEN
      SET contaNW = contaNW + 1;
      SET xNW = xNW + x;
      SET yNW = yNW + y;
    END IF;
  END LOOP scan;  
  CLOSE cursoreGPS;

  INSERT INTO RankQuadranti VALUES ( 'NE', contaNE, CONCAT('( ', TRUNCATE(xNE/contaNE, 2), ', ', TRUNCATE(yNE/contaNE, 2), ' )') ),
                                   ( 'SE', contaSE, CONCAT('( ', TRUNCATE(xSE/contaSE, 2), ', ', TRUNCATE(ySE/contaSE, 2), ' )') ), 
                                   ( 'SW', contaSW, CONCAT('( ', TRUNCATE(xSW/contaSW, 2), ', ', TRUNCATE(ySW/contaSW, 2), ' )') ),
                                   ( 'NW', contaNW, CONCAT('( ', TRUNCATE(xNW/contaNW, 2), ', ', TRUNCATE(yNW/contaNW, 2), ' )') );
  
  SELECT                                      
        RANK() OVER (ORDER BY PosizioniRegistrate DESC) AS `Rank`,
        `Quadrante`,        
        `PosizioniRegistrate`,
        `PosizioneMedia`
  FROM RankQuadranti;
  
END ;
;;
DELIMITER ;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--  ||     ANALYTICS 2: CONTROLLO QUALITA' DI PROCESSO     ||

-- ----------------------------------------------------------
-- CREAZIONE DELLA MATERIALIZED VIEW Report_QualitaProcesso
-- ----------------------------------------------------------
DROP TABLE IF EXISTS `Report_QualitaProcesso`;
CREATE TABLE `Report_QualitaProcesso`(
  `Lotto` int(11) NOT NULL,
  `PunteggioQualita` double NOT NULL,
  `FasiCritiche` varchar(100) DEFAULT '',
  PRIMARY KEY (Lotto)
  ) ENGINE = InnoDB DEFAULT CHARSET = latin1;
 -- ---------------------------------------------------------------
-- LOG TABLE log_lotti_prodotti che tiene nota dei lotti prodotti
-- ----------------------------------------------------------------
DROP TABLE IF EXISTS `log_lotti_prodotti`;
CREATE TABLE `log_lotti_prodotti`(
  `CodiceLotto` int(11) NOT NULL
) ENGINE = InnoDB DEFAULT CHARSET = Latin1;
DROP TRIGGER IF EXISTS push_lotti_prodotti;
-- ----------------------------------------
-- TRIGGER DI PUSH per log_lotti_prodotti
-- ----------------------------------------
-- NB: la data di produzione di un lotto viene inserita al termine dell'intero processo produttivo, dunque in un secondo momento rispetto all'inserimento del lotto.
DELIMITER $$
CREATE TRIGGER push_lotti_prodotti
AFTER UPDATE ON Lotto        
FOR EACH ROW
BEGIN   
  IF (OLD.DataProduzione IS NULL
      AND NEW.DataProduzione IS NOT NULL) THEN
    INSERT INTO log_lotti_prodotti VALUES (NEW.Codice);
  END IF;
END $$
DELIMITER ;
-- -------------------------------------------
-- FUNZIONE CALCOLA PUNTEGGIO FASE PRODUZIONE
-- -------------------------------------------
DROP FUNCTION IF EXISTS `CalcolaPunteggio`;
DELIMITER $$
CREATE FUNCTION CalcolaPunteggio(_soglia DOUBLE,
   							     _scostamento DOUBLE)
RETURNS DOUBLE DETERMINISTIC
BEGIN
  DECLARE punteggio DOUBLE DEFAULT 0; 
  SET punteggio = 25 - ( 1 - (_soglia - _scostamento) * 1 /(_soglia)) * 25; 
  RETURN punteggio;
END $$
DELIMITER ;
-- ----------------------------------------------------------------------
-- VALUTA IL PROCESSO PRODUTTIVO DI OGNI LOTTO INSERITO NELLA LOG TABLE
-- ----------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `ValutazioneLotto`;
DELIMITER $$
CREATE PROCEDURE ValutazioneLotto(OUT punteggio_qualita_ DOUBLE,
   							      OUT fasi_critiche_ VARCHAR(50))
BEGIN
  DECLARE finito INT DEFAULT 0;
  DECLARE numFasi INT DEFAULT 0;
  DECLARE fase INT DEFAULT NULL;
  DECLARE diff_durata INT DEFAULT 0;
  DECLARE diff_tempLatte DOUBLE DEFAULT 0;
  DECLARE diff_tempoRiposo INT DEFAULT 0;
  DECLARE diff_tempAmbiente DOUBLE DEFAULT 0;
  DECLARE fasiCritiche VARCHAR(50) DEFAULT '';
  DECLARE punteggioFase double DEFAULT 0;
  DECLARE punteggioTot double DEFAULT 0;
 
  DECLARE curFasi CURSOR FOR
  SELECT SL.Fase, SL.DiffDurata, SL.DiffTempLatte, SL.DiffTempoRiposo, SL.DiffTempAmbiente
  FROM ScostamentiFasiLotto SL; 
  
  DECLARE CONTINUE HANDLER
  FOR NOT FOUND SET finito = 1;
 
  OPEN curFasi;
  scan : LOOP
	FETCH curFasi INTO fase, diff_durata, diff_tempLatte, diff_tempoRiposo, diff_tempAmbiente;
 	IF finito = 1 THEN
   	 LEAVE scan;
    END IF;
    -- confronto gli scostamenti dei parametri con le soglie di tollerabilità: queste, se superate, comportano un punteggio pari a 0
    IF diff_durata < 5 THEN	  
      SET punteggioFase = punteggioFase + CalcolaPunteggio(5,diff_durata);
    END IF;    
	IF diff_tempLatte < 1.5 THEN
      SET punteggioFase = punteggioFase + CalcolaPunteggio(1.5,diff_tempLatte);
    END IF;
    IF diff_tempoRiposo < 5 THEN
      SET punteggioFase = punteggioFase + CalcolaPunteggio(5,diff_tempoRiposo);
    END IF;
    IF diff_tempAmbiente < 3 THEN
      SET punteggioFase = punteggioFase + CalcolaPunteggio(3,diff_tempAmbiente);
    END IF;
  -- controllo se la fase ha avuto seri problemi durante la produzione
    IF punteggioFase < 60 THEN
      SET fasiCritiche = CONCAT(fasiCritiche,' ',fase);
    END IF;
    SET punteggioTot = punteggioTot + punteggioFase;
    SET punteggioFase = 0;
    SET numFasi = numFasi + 1;    
  END LOOP scan;   
  CLOSE curFasi;
  
  SET punteggio_qualita_ = punteggioTot/numFasi;
  SET fasi_critiche_ = fasiCritiche;
  
END $$
DELIMITER ;
-- ----------------------------------------
-- REFRESH DELLA MV Report_QualitaProcesso
-- ----------------------------------------
DROP PROCEDURE IF EXISTS `Refresh_QualitaProcesso`;
DELIMITER ;;
CREATE PROCEDURE Refresh_QualitaProcesso(OUT esito bool)
BEGIN
  DECLARE _lotto int(11) DEFAULT NULL;
  DECLARE _fase int(11) DEFAULT NULL;
  DECLARE _pun int(11) DEFAULT NULL;
  DECLARE finito bool DEFAULT 0;
    
  DECLARE `cursoreFasi` CURSOR FOR 
    SELECT LP.CodiceLotto,
           FP.NumeroProgressivo
    FROM log_lotti_prodotti LP
         INNER JOIN
         FaseProduzione FP ON FP.Lotto = LP.CodiceLotto
    ORDER BY LP.CodiceLotto, FP.NumeroProgressivo;
    
  DECLARE CONTINUE HANDLER FOR NOT FOUND 
    SET finito = 1;
    
  -- esito vale 1 in caso di errore grave
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET esito = 1;
    SELECT 'Si e` verificato un errore: Report_QualitaProcesso non aggiornata';
  END;
  
-- inizializzo _pun con il primo lotto della log table
  SELECT LP.CodiceLotto INTO _pun
  FROM log_lotti_prodotti LP
  ORDER BY LP.CodiceLotto
  LIMIT 1;
  
-- inizializzo la variabile di uscita  
  SET esito = 0;
  
  CREATE TEMPORARY TABLE IF NOT EXISTS `ScostamentiFasiLotto`(
    `Lotto` int(11) NOT NULL,
    `Fase` int(11) NOT NULL,
    `DiffDurata` int(11) NOT NULL, 
	`DiffTempLatte` double NOT NULL,
   	`DiffTempoRiposo` int(11) NOT NULL, 
    `DiffTempAmbiente` double NOT NULL,    
	PRIMARY KEY (Lotto, Fase)
	) ENGINE = InnoDB DEFAULT CHARSET = Latin1;
  TRUNCATE TABLE ScostamentiFasiLotto;
  
  OPEN cursoreFasi;
  scan: LOOP
    FETCH cursoreFasi INTO _lotto, _fase;
    IF finito = 1 THEN 
      LEAVE scan;
	END IF;
    
    CALL ScostamentoFaseProduzione (_lotto, _fase, @durata, @tempLatte, @riposo, @tempAmbiente);
    
    IF _lotto = _pun THEN
      INSERT INTO ScostamentiFasiLotto VALUES (_lotto, _fase, ABS(@durata), ABS(@tempLatte), ABS(@riposo), ABS(@tempAmbiente));
    ELSE
   -- algoritmo di valutazione degli scostamenti delle fasi di un lotto (usare i valori nella temporary)
      CALL ValutazioneLotto(@punteggio, @criticita);
   -- inserimento della valutazione nella MV Report_QualitaProcesso
      REPLACE INTO Report_QualitaProcesso
      SELECT _pun, @punteggio, @criticita ;
   -- elimino i record della temporary table, poiché ho finito di valutare il lotto precedente a quello puntato dal cursore
      TRUNCATE TABLE ScostamentiFasiLotto; 
   -- aggiorno la variabile _pun con il codice del lotto attualmente puntato dal cursore
      SET _pun = _lotto;                  
      INSERT INTO ScostamentiFasiLotto VALUES (_lotto, _fase, ABS(@durata), ABS(@tempLatte), ABS(@riposo), ABS(@tempAmbiente));
    END IF;    
  END LOOP scan;
  CLOSE cursoreFasi;
  
-- replico l'algoritmo di valutazione e l'inserimento nella MV (perchè altrimenti resterebbe fuori l'ultimo lotto puntato dal cursore)
  CALL ValutazioneLotto(@punteggio, @criticita);
  REPLACE INTO Report_QualitaProcesso
  SELECT _pun, @punteggio, @criticita;
    
  TRUNCATE TABLE ScostamentiFasiLotto;
  TRUNCATE TABLE log_lotti_prodotti;
END ;
;;
DELIMITER ;
-- --------------------------------------------------------------
-- DEFERRED REFRESH: chiamo Refresh_QualitaProcesso con un EVENT
-- --------------------------------------------------------------
DELIMITER ;;
CREATE EVENT `Refresh_MV_QualitaProcesso`
ON SCHEDULE EVERY 1 DAY
STARTS '2020-01-01 23:55:00'
DO
 BEGIN
   SET @esito = 0;
   CALL Refresh_QualitaProcesso(@esito);
   IF @esito = 1 THEN
     SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'Errore refresh.';
   END IF;
 END ;
;;
DELIMITER ;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--  ||     ANALYTICS 3: TRACCIABILITA DI FILIERA     ||

DROP PROCEDURE IF EXISTS `RankLaboratori`;
DELIMITER ;;
CREATE PROCEDURE RankLaboratori(IN _dataInizio date,
								IN _dataFine date)
BEGIN
  DECLARE _giorni int(11) DEFAULT 0;  
  SET _giorni = DATEDIFF(_dataFine,_dataInizio);  
  
  SELECT RANK() OVER( ORDER BY  AVG(QP.PunteggioQualita)  DESC) AS `Rank`,
	     L.Laboratorio,
         COUNT(*) AS LottiProdotti,
         AVG(QP.PunteggioQualita) AS PunteggioMedio,
         (100 * COUNT(*) ) / (_giorni * D.NumeroDipendenti * 0.2) AS PercentualeCaricoLavorativo  -- Dalla tavola dei volumi, si evince che un dipendente produce giornalmente una media di 0.2 lotti
  FROM Report_QualitaProcesso QP
       INNER JOIN
       Lotto L ON QP.Lotto = L.Codice
       INNER JOIN
       (SELECT DI.Laboratorio,
	  	       COUNT(*) AS NumeroDipendenti
        FROM Dipendente DI
        GROUP BY DI.Laboratorio 
       ) AS D  ON L.Laboratorio = D.Laboratorio
  WHERE L.DataProduzione BETWEEN _dataInizio AND _dataFine
  GROUP BY L.Laboratorio;

END ;
;;
DELIMITER ;




-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--                                                                             INSERIMENTO DATI
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- ------------------------------------
-- Records of 'Indirizzo'
-- ------------------------------------
BEGIN;
INSERT INTO `Indirizzo` VALUES ('Porto Azzurro', 'Delle Frisone', '37', '57036'), ('Agrigento', 'Cretese', '45', '59873');
COMMIT;

-- ------------------------------------
-- Records of 'Agriturismo'
-- ------------------------------------
BEGIN;
INSERT INTO `Agriturismo` VALUES ('Il Noce', 'Porto Azzurro', 'Delle Frisone', '37');
COMMIT;

-- ------------------------------------
-- Records of 'Stalla'
-- ------------------------------------ 
BEGIN;
INSERT INTO `Stalla` (Agriturismo) VALUES ('Il Noce'), ('Il Noce'), ('Il Noce');
COMMIT;

-- ------------------------------------
-- Records of 'Locale'
-- ------------------------------------
BEGIN;
INSERT INTO `Locale`(Stalla, Pavimentazione, OrientazioneFinestre, Altezza, Lunghezza, Larghezza) VALUES ('1', 'Fessurato', 'Sud', 3, 5, 5), ('1', 'Fessurato', 'Nord', 3, 4, 5), ('1', 'Fessurato', 'Nord', 3, 3, 5), ('1', 'Pieno', 'Sud', 3, 5, 5), ('1', 'Pieno', 'Nord', 3, 4, 5), ('1', 'Pieno', 'Sud', 3, 3, 5), ('1', 'Fessurato', 'Ovest', 3, 5, 5), ('1', 'Pieno', 'Ovest', 3, 5, 3), ('1', 'Pieno', 'Nord', 3, 4, 5), ('1', 'Fessurato', 'Nord', 3, 5, 5);
COMMIT;

-- ------------------------------------
-- Records of 'ParametriLocale'
-- ------------------------------------
BEGIN;
INSERT INTO `ParametriLocale`(Ora, Data, Locale, Temperatura, Umidita) VALUES ('12:00:00', '2020-01-23', 1, 18, 60), ('12:00:00', '2020-01-23', 2, 19, 61), ('12:00:00', '2020-01-23', 3, 18.5, 59), ('12:00:00', '2020-01-23', 4, 17.8, 62), ('12:00:00', '2020-01-23', 5, 20, 58), ('12:00:00', '2020-01-23', 6, 19, 61), ('12:00:00', '2020-01-23', 7, 18, 60), ('12:00:00', '2020-01-23', 8, 18.9, 61), ('12:00:00', '2020-01-23', 9, 18, 59.2), ('12:00:00', '2020-01-23', 10, 18, 60);
COMMIT;

-- ------------------------------------
-- Records of 'CondizioneLocale'
-- ------------------------------------
BEGIN;
INSERT INTO `CondizioneLocale`(Ora, Data, Locale, Azoto, Metano, LivelloSporcizia) VALUES ('15:38', '2020-01-19', 3, 78.1, 0.0005, 7);
COMMIT;

-- ------------------------------------
-- Records of 'Mangiatoia'
-- ------------------------------------
BEGIN;
INSERT INTO `Mangiatoia`(Tipologia, Locale) VALUES ('Angolato', 1), ('Rastrelliera', 2), ('Portaballone', 3), ('Angolato', 4), ('Rastrelliera', 5), ('Portaballone', 6), ('Angolato', 7), ('PortaBallone', 8), ('Rastrelliera', 9), ('Angolato', 10);
COMMIT;

-- ------------------------------------
-- Records of 'Pasto'
-- ------------------------------------
BEGIN;
INSERT INTO `Pasto`(Data, Ora, Mangiatoia) VALUES ('2020-01-23', '12:00:00', 1), ('2020-01-23', '12:00:00', 2), ('2020-01-23', '12:00:00', 3), ('2020-01-23', '12:00:00', 4), ('2020-01-23', '12:00:00', 5);
COMMIT;

-- ------------------------------------
-- Records of 'Foraggio'
-- ------------------------------------
BEGIN;
INSERT INTO `Foraggio`(Data, Ora, Mangiatoia, Quantita) VALUES ('2020-01-23', '12:00:00', 1, 8), ('2020-01-23', '12:00:00', 2, 4), ('2020-01-23', '12:00:00', 3, 3), ('2020-01-23', '12:00:00', 4, 8), ('2020-01-23', '12:00:00', 5, 3),
															   ('2020-01-23', '13:00:00', 1, 5), ('2020-01-23', '13:00:00', 2, 3), ('2020-01-23', '13:00:00', 3, 2.3), ('2020-01-23', '13:00:00', 4, 6), ('2020-01-23', '13:00:00', 5, 2),
                                                               ('2020-01-23', '14:00:00', 1, 3.4), ('2020-01-23', '14:00:00', 2, 2.5), ('2020-01-23', '14:00:00', 3, 1.6), ('2020-01-23', '14:00:00', 4, 4.5), ('2020-01-23', '14:00:00', 5, 1.5),
															   ('2020-01-23', '15:00:00', 1, 2), ('2020-01-23', '15:00:00', 2, 2), ('2020-01-23', '15:00:00', 3, 1.1), ('2020-01-23', '15:00:00', 4, 4), ('2020-01-23', '15:00:00', 5, 0.8),
															   ('2020-01-23', '16:00:00', 1, 1.1), ('2020-01-23', '16:00:00', 2, 1.2), ('2020-01-23', '16:00:00', 3, 0.4), ('2020-01-23', '16:00:00', 4, 2), ('2020-01-23', '16:00:00', 5, 0.2),
															   ('2020-01-23', '17:00:00', 1, 0.6), ('2020-01-23', '17:00:00', 2, 0.5), ('2020-01-23', '17:00:00', 3, 0.2), ('2020-01-23', '17:00:00', 4, 0.9), ('2020-01-23', '17:00:00', 5, 0),
															   ('2020-01-23', '18:00:00', 1, 0.3), ('2020-01-23', '18:00:00', 2, 0.2), ('2020-01-23', '18:00:00', 3, 0), ('2020-01-23', '18:00:00', 4, 0.3), ('2020-01-23', '18:00:00', 5, 0);
COMMIT;

-- ------------------------------------
-- Records of 'IngredienteForaggio'
-- ------------------------------------
BEGIN;
INSERT INTO `IngredienteForaggio`(Nome, Modalita, Fibre, Kcal, Glucidi, Proteine) VALUES ('Sorgo', 'Fresco', 63, 3270, 700, 115), ('Fieno', 'Essiccato', 246, 3230, 583.5 ,230), ('Erba', 'Fresco', 250, 100, 44, 33), ('Tritello di grano', 'Essiccato', 107, 3400, 719, 132.1), ('Granturco', 'Insilato', 20, 3560, 25, 92);
COMMIT;

-- ------------------------------------
-- Records of 'Composizione'
-- ------------------------------------
BEGIN;
INSERT INTO `Composizione` (DataPasto, OraPasto, Mangiatoia, NomeIngrediente, ModalitaIngrediente, Quantita) VALUES ('2020-01-23', '12:00:00', 1, 'Erba', 'Fresco', 8), 
                                                                                                                    ('2020-01-23', '12:00:00', 2, 'Tritello di grano', 'Essiccato', 2), ('2020-01-23', '12:00:00', 2, 'Sorgo', 'Fresco', 2), 
                                                                                                                    ('2020-01-23', '12:00:00', 3, 'Fieno', 'Essiccato', 3), 
                                                                                                                    ('2020-01-23', '12:00:00', 4, 'Fieno', 'Essiccato', 8), 
                                                                                                                    ('2020-01-23', '12:00:00', 5, 'Erba', 'Fresco', 3);
COMMIT;

-- ------------------------------------
-- Records of 'Abbeveratoio'
-- ------------------------------------
BEGIN;
INSERT INTO `Abbeveratoio` (Tipologia, Locale) VALUES ('A galleggiante', 1), ('A galleggiante', 1), 
                                                      ('A galleggiante', 2), ('A galleggiante', 2), 
                                                      ('A galleggiante', 3), ('A galleggiante', 3), 
                                                      ('A galleggiante', 4), ('A galleggiante', 4), 
                                                      ('A galleggiante', 5), ('A galleggiante', 5), 
                                                      ('A galleggiante', 6), ('A galleggiante', 6), 
                                                      ('A galleggiante', 7), ('A galleggiante', 7), 
                                                      ('A galleggiante', 8), ('A galleggiante', 8), 
                                                      ('A galleggiante', 9), ('A galleggiante', 9), 
                                                      ('A galleggiante', 10), ('A galleggiante', 10);
COMMIT;

-- ------------------------------------
-- Records of 'Sostanza'
-- ------------------------------------
BEGIN;
INSERT INTO `Sostanza` (Nome, Data, Ora, Abbeveratoio, Quantita) VALUES ('Potassio', '2020-01-23', '10:00:00', 12, 8), ('Vitamina C', '2020-01-24', '16:00:00', 12, 3);
COMMIT;

-- ------------------------------------
-- Records of 'Illuminazione'
-- ------------------------------------
BEGIN;
INSERT INTO `Illuminazione` (Tipologia, Intensita, ColoreLuce, Locale) VALUES ('Led', 400, 'Giallo', 1), ('Led', 400, 'Giallo', 1), ('Led', 600, 'Giallo', 2), ('Incandescenza', 250, 'Giallo', 3), ('Incandescenza', 250, 'Giallo', 3), ('Incandescenza', 250, 'Giallo', 3), ('Fluorescenza', 600, 'Bianco', 4), ('Led', 600, 'Giallo', 5), ('Led', 600, 'Giallo', 6), ('Led', 600, 'Giallo', 7), ('Led', 600, 'Giallo', 8), ('Led', 600, 'Giallo', 9), ('Led', 600, 'Giallo', 10);
COMMIT;

-- ------------------------------------
-- Records of 'Condizionamento'
-- ------------------------------------
BEGIN;
INSERT INTO `Condizionamento` (Tipologia, Potenza, Locale) VALUES ('Climatizzatore', 8000,  1), ('Climatizzatore', 8000,  2), ('Climatizzatore', 8000,  3), ('Climatizzatore', 8000,  4), ('Climatizzatore', 8000,  5), ('Climatizzatore', 8000,  6), ('Climatizzatore', 8000,  7), ('Climatizzatore', 8000,  8), ('Climatizzatore', 8000,  9), ('Climatizzatore', 8000,  10);
COMMIT;

-- ------------------------------------
-- Records of 'Specie'
-- ------------------------------------
BEGIN;
INSERT INTO `Specie` (Specie, Famiglia) VALUES ('Bovina', 'Bovidi'), ('Ovina', 'Bovidi'), ('Caprina', 'Bovidi');
COMMIT;

-- ------------------------------------
-- Records of 'Razza'
-- ------------------------------------
BEGIN;
INSERT INTO `Razza` (Razza, Specie) VALUES ('Frisona', 'Bovina'), ('Chianina', 'Bovina'), ('Piemontese', 'Bovina'), ('Maremmana', 'Bovina'), 
                                           ('Sarda', 'Ovina'), ('Massese', 'Ovina'), ('Altamurana', 'Ovina'), 
                                           ('Alpina francese', 'Caprina'), ('Boera', 'Caprina');
COMMIT;

-- ------------------------------------
-- Records of 'Animale'
-- ------------------------------------
BEGIN;
INSERT INTO `Animale`(Razza, Sesso, Altezza, Peso, Locale) VALUES ('Frisona', 'F', '1.5', 580, 1), ('Frisona', 'M', 1.6, 1100, 1), ('Frisona', 'F', '1.4', 520, 1), ('Frisona', 'F', '1.45', 550, 1), ('Frisona', 'F', 1.55, 700, 1),
                                                                  ('Sarda', 'M', 0.8, 75, 2), ('Sarda', 'F', 0.7, 60, 2), ('Sarda', 'F', 0.6, 65, 2), ('Sarda', 'F', 0.7, 62, 2), ('Sarda', 'F', 0.68, 59, 2),
																  ('Sarda', 'F', 0.7, 60, 3), ('Massese', 'F', 0.7, 58, 3), ('Sarda', 'F', 0.7, 62, 3), ('Sarda', 'M', 0.68, 58, 3), 
                                                                  ('Chianina', 'M', 2.0, 1500, 4), ('Chianina', 'F', 1.9, 1400, 4), ('Chianina', 'F', 1.8, 1300, 4), ('Piemontese', 'M', 1.4, 800, 4), ('Piemontese', 'F', 1.3, 750, 4);
COMMIT;

-- ------------------------------------
-- Records of 'Recinto'
-- ------------------------------------
BEGIN;
INSERT INTO `Recinto` (Agriturismo) VALUES ('Il Noce');
COMMIT;

-- ------------------------------------
-- Records of 'RecinzioneFissa'
-- ------------------------------------
BEGIN;
INSERT INTO `RecinzioneFissa` (Lat1, Long1, Lat2, Long2, Recinto) VALUES (0, 0, 15, 0, 1), (15, 0, 15, 5, 1), (15, 5, 0, 5, 1), (0, 5, 0, 0, 1);
COMMIT;

-- ------------------------------------
-- Records of 'ZonaDiPascolo'
-- ------------------------------------
BEGIN;
INSERT INTO `ZonaDiPascolo` (Recinto) VALUES (1), (1), (1);
COMMIT;

-- ------------------------------------
-- Records of 'Recinzione'
-- ------------------------------------
BEGIN;
INSERT INTO `Recinzione` (Lat1, Long1, Lat2, Long2) VALUES (0,0,0,5), (5,0,0,5), (10,0,0,5), (15,0,0,5),
                                                           (0,0,5,0), (5,0,10,0), (10,0,15,0),   (0,5,5,5), (5,5,10,5), (10,5,15,5);
COMMIT;

-- ------------------------------------
-- Records of 'DelimitataDa'
-- ------------------------------------
BEGIN;
INSERT INTO `DelimitataDa` (Recinto, ZonaPascolo, Recinzione) VALUES (1,1,1), (1,1,2), (1,1,5), (1,1,8),
																	 (1,2,2), (1,2,6), (1,2,3), (1,2,9),
                                                                     (1,3,3), (1,3,7), (1,3,4), (1,3,10);
COMMIT;

-- ------------------------------------
-- Records of 'AttivitaPascolo'
-- ------------------------------------
BEGIN;
INSERT INTO `AttivitaPascolo` (Data, OraInizio, Recinto, ZonaPascolo, OraFine) VALUES ('2020-01-31', '07:00:00', 1, 1, '13:00:00'),
                                                                                      ('2020-01-31', '08:00:00', 1, 2, '13:00:00'),('2020-01-31', '14:00:00', 1, 2, '19:00:00'),
                                                                                      ('2020-01-31', '09:00:00', 1, 3, '15:00:00');
COMMIT;

-- ------------------------------------
-- Records of 'UscitaPascolo'
-- ------------------------------------
BEGIN;
INSERT INTO `UscitaPascolo` (Animale, Data, OraInizio, Recinto, ZonaPascolo, OraRientro) VALUES (1, '2020-01-31', '07:00:00', 1, 1, '13:00:00'), (2, '2020-01-31', '07:00:00', 1, 1, '13:02:00'), (3, '2020-01-31', '07:00:00', 1, 1, '13:00:00'), (4, '2020-01-31', '07:00:00', 1, 1, '13:01:40'), (5, '2020-01-31', '07:00:00', 1, 1, '13:00:00'),
                                                                                                (6, '2020-01-31', '08:00:00', 1, 2, '13:00:00'), (7, '2020-01-31', '08:00:00', 1, 2, '13:00:00'), (8, '2020-01-31', '08:00:00', 1, 2, '13:01:25'), (9, '2020-01-31', '08:00:00', 1, 2, '13:00:00'), (10, '2020-01-31', '08:00:00', 1, 2, '13:00:00'),
                                                                                                (11, '2020-01-31', '14:00:00', 1, 2, '19:00:00'), (12, '2020-01-31', '14:00:00', 1, 2, '19:00:00'), (13, '2020-01-31', '14:00:00', 1, 2, '19:00:00'), (14, '2020-01-31', '14:00:00', 1, 2, '19:00:00'),
																					            (15, '2020-01-31', '09:00:00', 1, 3, '15:00:00'), (16, '2020-01-31', '09:00:00', 1, 3, '15:00:00'), (17, '2020-01-31', '09:00:00', 1, 3, '15:00:00'), (18, '2020-01-31', '09:00:00', 1, 3, '15:00:00'), (19, '2020-01-31', '09:00:00', 1, 3, '15:00:25');
COMMIT;

-- ------------------------------------
-- Records of 'PosizioneAnimale'
-- ------------------------------------
BEGIN;
INSERT INTO `PosizioneAnimale` (Animale, Data, Ora, Latitudine, Longitudine) VALUES (1, '2020-01-31', '08:00:00', 2, 2), (1, '2020-01-31', '09:00:00', 3, 4), (1, '2020-01-31', '10:00:00', 3, 4), (1, '2020-01-31', '11:00:00', 2.2, 3.5), (1, '2020-01-31', '12:00:00', 3, 4), (1, '2020-01-31', '13:00:00', 2, 2),
																					(2, '2020-01-31', '08:00:00', 3, 2), (2, '2020-01-31', '09:00:00', 4, 4), (2, '2020-01-31', '10:00:00', 3, 4.5), (2, '2020-01-31', '11:00:00', 3.2, 3.5), (2, '2020-01-31', '12:00:00', 2, 2), (2, '2020-01-31', '13:00:00', 1, 3),
                                                                                    (3, '2020-01-31', '08:00:00', 3, 3), (3, '2020-01-31', '09:00:00', 2, 2.5), (3, '2020-01-31', '10:00:00', 2, 2), (3, '2020-01-31', '11:00:00', 1.2, 2.5), (3, '2020-01-31', '12:00:00', 2, 3), (3, '2020-01-31', '13:00:00', 2, 1),
                                                                                    (4, '2020-01-31', '08:00:00', 4, 3.5), (4, '2020-01-31', '09:00:00', 4, 4.5), (4, '2020-01-31', '10:00:00', 3, 2), (4, '2020-01-31', '11:00:00', 1, 2), (4, '2020-01-31', '12:00:00', 3, 3), (4, '2020-01-31', '13:00:00', 3, 1),
                                                                                    (5, '2020-01-31', '08:00:00', 1.1, 1.2), (5, '2020-01-31', '09:00:00', 1, 1.5), (5, '2020-01-31', '10:00:00', 1.1, 1.2), (5, '2020-01-31', '11:00:00', 1.2, 1.1), (5, '2020-01-31', '12:00:00', 1, 1.2), (5, '2020-01-31', '13:00:00', 1, 1);
COMMIT;

-- ------------------------------------
-- Records of 'Fornitore'
-- ------------------------------------
BEGIN;
INSERT INTO `Fornitore`(PartitaIva, Nome, RagioneSociale, Citta, Via, NumeroCivico) VALUES (123456, 'Perillo', 'Falaride Srl', 'Agrigento', 'Cretese', '45');
COMMIT;

-- ------------------------------------
-- Records of 'AnimaleAcquistato'
-- ------------------------------------
BEGIN;
INSERT INTO `AnimaleAcquistato`(Codice, DataNascita, IdPadre, IdMadre, Fornitore, DataArrivo, DataAcquisto) VALUES (1, '2009-05-15', 'PA01', 'MA01', 123456,'2016-01-08', '2016-01-24'),
                                                                                                                   (2, '2007-03-05', 'PA02', 'MA02', 123456,'2016-01-08', '2016-01-24');
COMMIT;

-- ------------------------------------
-- Records of 'Veterinario'
-- ------------------------------------
BEGIN;
INSERT INTO `Veterinario`(Codice, Nome, Cognome) VALUES (1, 'Filippide', 'Di Maratona'), (2, 'Diogene', 'Il Cinico');
COMMIT;

-- ------------------------------------
-- Records of 'Riproduzione'
-- ------------------------------------
BEGIN;
INSERT INTO `Riproduzione` (Data, Ora, Esito, Padre, Madre, Veterinario) VALUES ('2016-06-15', '09:15:00', 0, 2, 1, 1);
COMMIT;

-- ------------------------------------
-- Records of 'Gestazione'
-- ------------------------------------
BEGIN;
INSERT INTO `Gestazione` (CodiceRiproduzione, DataFine, Veterinario) VALUES (1, '2017-03-10', 1);
COMMIT;

-- ------------------------------------
-- Records of 'Complicanza'
-- ------------------------------------
BEGIN;
INSERT INTO `Complicanza` (CodiceRiproduzione, Data, Ora, Nome) VALUES (1, '2017-03-10', '07:15:00', 'posizione feto anormale');
COMMIT;

-- ------------------------------------
-- Records of 'AnimaleNato'
-- ------------------------------------
BEGIN;
INSERT INTO `AnimaleNato` VALUES (3,1);
COMMIT;

-- ------------------------------------
-- Records of 'ControlloProgrammato'
-- ------------------------------------
BEGIN;
INSERT INTO `ControlloProgrammato` VALUES (1, '2017-03-01');
COMMIT;

-- ------------------------------------
-- Records of 'Terapia'
-- ------------------------------------
BEGIN;
INSERT INTO `Terapia` (DataInizio, DataFine) VALUES ('2019-06-14', '2019-06-30'), ('2019-07-01', '2019-08-01');
COMMIT;

-- ------------------------------------
-- Records of 'ControlloEffettuato'
-- ------------------------------------
BEGIN;
INSERT INTO `ControlloEffettuato` (CodiceRiproduzione, DataProgrammata, Data, Esito, Veterinario) VALUES (1, '2017-03-01', '2017-03-03', 0, 2);
COMMIT;

-- ------------------------------------
-- Records of 'ProceduraEsame'
-- ------------------------------------
BEGIN;
INSERT INTO `ProceduraEsame` (NomeEsame, Macchinario, Procedura) VALUES ('Ecografia', 'Ecografo', 'Applicare un modesto quantitativo di gel...');
COMMIT;

-- ------------------------------------
-- Records of 'EsameDiagnostico'
-- ------------------------------------
BEGIN;
INSERT INTO `EsameDiagnostico` (NomeEsame, Data, CodiceRiproduzione, DataProgrammata) VALUES ('Ecografia', '2017-03-04', 1, '2017-03-01');
COMMIT;

-- ------------------------------------
-- Records of 'VisitaDiControllo'
-- ------------------------------------
BEGIN;
INSERT INTO `VisitaDiControllo` (Animale, Data, Ora, MassaMagra, MassaGrassa, Veterinario) VALUES (15, '2019-06-14', '16:00:00', 60, 40, 2), (15, '2019-07-01', '16:00:00', 60, 40, 2);
COMMIT;

-- ------------------------------------
-- Records of 'IndicatoreOggettivo'
-- ------------------------------------
BEGIN;
INSERT INTO `IndicatoreOggettivo` (Nome, Animale, DataVisita, OraVisita) VALUES ('Emocromo', 15, '2019-06-14', '16:00:00');
COMMIT;

-- ------------------------------------
-- Records of 'Parametro'
-- ------------------------------------
BEGIN;
INSERT INTO `Parametro` VALUES ('Hct'), ('Hb'), ('RBC'), ('MCV'), ('MCH'), ('MCHC'), ('RDW'), ('Reticolociti');
COMMIT;

-- ------------------------------------
-- Records of 'DeterminatoDa'
-- ------------------------------------
BEGIN;
INSERT INTO `DeterminatoDa` (Parametro, IndicatoreOggettivo, Animale, DataVisita, OraVisita, Valore) VALUES ('Hct', 'Emocromo', 15, '2019-06-14', '16:00:00', 50), 
                                                                                                            ('Hb', 'Emocromo', 15, '2019-06-14', '16:00:00', 17.5),
                                                                                                            ('RBC', 'Emocromo', 15, '2019-06-14', '16:00:00', 4.7),
                                                                                                            ('MCV', 'Emocromo', 15, '2019-06-14', '16:00:00', 90),
                                                                                                            ('MCH', 'Emocromo', 15, '2019-06-14', '16:00:00', 30),
                                                                                                            ('MCHC', 'Emocromo', 15, '2019-06-14', '16:00:00', 35),
                                                                                                            ('RDW', 'Emocromo', 15, '2019-06-14', '16:00:00', 13.4),
                                                                                                            ('Reticolociti', 'Emocromo', 15, '2019-06-14', '16:00:00', 2.3);
COMMIT;

-- ------------------------------------
-- Records of 'DisturboComportamentale'
-- ------------------------------------
BEGIN;
INSERT INTO `DisturboComportamentale` (Nome, Animale, DataVisita, OraVisita, Entita) VALUES ('Inappetenza', 15, '2019-06-14', '16:00:00', 'Moderata'), ('Inappetenza', 15, '2019-07-01', '16:00:00', 'Moderata');
COMMIT;

-- ------------------------------------
-- Records of 'Lesione'
-- ------------------------------------
BEGIN;
INSERT INTO `Lesione` (Tipologia, ParteCorpo, Animale, DataVisita, OraVisita, Entita) VALUES ('Escoriazione', 'Zampa anteriore dx', 15, '2019-06-14', '16:00:00', 'Lieve');
COMMIT;

-- ------------------------------------
-- Records of 'StatoDiSalute'
-- ------------------------------------
BEGIN;
INSERT INTO `StatoDiSalute` (Animale, DataVisita, OraVisita, Vigilanza, Deambulazione, Respirazione, Idratazione, LucentezzaPelo) VALUES (15, '2019-06-14', '16:00:00', 9, 6, 4, 6, 7), (15, '2019-07-01', '16:00:00', 8, 6, 5, 7, 7);
COMMIT;

-- ------------------------------------
-- Records of 'Patologia'
-- ------------------------------------
BEGIN;
INSERT INTO `Patologia` (Nome, Animale, DataVisita, OraVisita, CodiceTerapia) VALUES ('Bronchite', 15, '2019-06-14', '16:00:00', 1), ('Bronchite', 15, '2019-07-01', '16:00:00', 2);
COMMIT;

-- ------------------------------------
-- Records of 'PeriodoFarmaco'
-- ------------------------------------
BEGIN;
INSERT INTO `PeriodoFarmaco` (CodiceTerapia, Farmaco, DataInizio, DataFine, GiorniDiPausa, GiorniConsecutivi) VALUES (1, 'Augmentin', '2019-06-14', '2019-06-30', 0, 17),
                                                                                                                     (2, 'Amoxil', '2019-07-01', '2019-07-10', 0, 11),
                                                                                                                     (2, 'Amoxil', '2019-07-11', '2019-08-01', 2, 1),
                                                                                                                     (2, 'Pantoprazolo', '2019-07-01', '2019-08-01', 0, 31);
COMMIT;

-- ------------------------------------
-- Records of 'SomministrazioneNonContinuativa'
-- ------------------------------------
BEGIN;
INSERT INTO `SomministrazioneNonContinuativa` (CodiceTerapia, Farmaco, DataInizio, NumeroGiornoConsecutivo, Orario, Dose) VALUES  (2, 'Amoxil', '2019-07-11', 1, '20:00:00', 1000);
COMMIT;


-- ------------------------------------
-- Records of 'SomministrazioneContinuativa'
-- ------------------------------------
BEGIN;
INSERT INTO `SomministrazioneContinuativa` (CodiceTerapia, Farmaco, DataInizio, Orario, Dose) VALUES (1, 'Augmentin', '2019-06-14', '08:00:00', 2000), (1, 'Augmentin', '2019-06-14', '20:00:00', 2000),
                                                                                                     (2, 'Pantoprazolo', '2019-07-01', '20:00:00', 50), (2, 'Amoxil', '2019-07-01', '08:00:00', 2000), (2, 'Amoxil', '2019-07-01', '20:00:00', 2000), 
                                                                                                     (2, 'Amoxil', '2019-07-11', '08:00:00', 1000);
COMMIT;

-- ------------------------------------
-- Records of 'Quarantena'
-- ------------------------------------
   -- Gestito dal trigger --
UPDATE Terapia
SET Esito = 1
WHERE Codice = 1;
UPDATE Terapia
SET Esito = 1
WHERE Codice = 2;

-- ------------------------------------
-- Records of 'Mungitrice'
-- ------------------------------------
BEGIN;
INSERT INTO `Mungitrice` (Marca, Modello, Agriturismo, Latitudine, Longitudine) VALUES ('Tecnosac', 'TS-17', 'Il Noce', 25, 25), ('Tecnosac', 'TS-17', 'Il Noce', 25.2, 25), ('Tecnosac', 'TS-17', 'Il Noce', 25.4, 25), 
																					   ('Tecnosac', 'TS-18', 'Il Noce', 25, 25.2), ('Tecnosac', 'TS-18', 'Il Noce', 25.2, 25.2),('Tecnosac', 'TS-18', 'Il Noce', 25.4, 25.2);
COMMIT;

-- ------------------------------------
-- Records of 'Silos'
-- ------------------------------------
BEGIN;
INSERT INTO `Silos` (Capacita, Agriturismo) VALUES ( 500, 'Il Noce'), ( 500, 'Il Noce'), ( 500, 'Il Noce'), ( 500, 'Il Noce'), ( 500, 'Il Noce'), ( 500, 'Il Noce'), ( 500, 'Il Noce'), ( 500, 'Il Noce');
COMMIT;

-- ------------------------------------
-- Records of 'Mungitura'
-- ------------------------------------
BEGIN;
INSERT INTO `Mungitura` (Animale, Data, OraInizio, OraFine, QuantitaLatte, Mungitrice, Silos, Grasso, Proteine, Lattosio) VALUES (1, '2020-01-28', '08:00:00', '08:10:00', 5, 1, 1, 3.7, 2.9, 4.9), (2, '2020-01-28', '08:00:00', '08:10:00', 4.5, 2, 1, 3.8, 3, 4.9), (3, '2020-01-28', '08:00:00', '08:10:00', 5.2, 3, 1, 3.7, 2.8, 4.9), (4, '2020-01-28', '08:00:00', '08:10:00', 5, 4, 1, 3.7, 2.9, 4.9),
                                                                                                                                 (7, '2020-01-28', '08:00:00', '08:10:00', 1.8, 5, 2, 4.6, 5, 4.8), (8, '2020-01-28', '08:00:00', '08:10:00', 1.5, 6, 2, 4.8, 5.2, 4.8), 
                                                                                                                                 (9, '2020-01-28', '08:15:00', '08:25:00', 1.6, 5, 2, 4.5, 5.1, 4.8), (10, '2020-01-28', '08:15:00', '08:25:00', 2, 6, 2, 4.6, 5, 4.8), (13, '2020-01-28', '08:15:00', '08:25:00', 1.9, 1, 2, 4.7, 5.1, 4.8),
                                                                                                                                 (11, '2020-01-28', '08:30:00', '08:40:00', 2.1, 5, 2, 4.7, 4.9, 4.8), (12, '2020-01-28', '08:30:00', '08:40:00', 2, 6, 3, 7, 6, 4.8), 
                                                                                                                                 (16, '2020-01-28', '08:15:00', '08:25:00', 3, 2, 4, 4.5, 3.3, 4.9), (17, '2020-01-28', '08:15:00', '08:25:00', 3, 3, 4, 4.5, 3.3, 4.9), (19, '2020-01-28', '08:15:00', '08:25:00', 3.2, 4, 4, 4.4, 3.1, 4.9),
                                                                                                                                 (1, '2020-01-29', '08:00:00', '08:10:00', 5, 1, 1, 3.7, 2.9, 4.9), (2, '2020-01-29', '08:00:00', '08:10:00', 4.5, 2, 1, 3.8, 3, 4.9), (3, '2020-01-29', '08:00:00', '08:10:00', 5.2, 3, 1, 3.7, 2.8, 4.9), (4, '2020-01-29', '08:00:00', '08:10:00', 5, 4, 1, 3.7, 2.9, 4.9),
                                                                                                                                 (7, '2020-01-29', '08:00:00', '08:10:00', 1.8, 5, 2, 4.6, 5, 4.8), (8, '2020-01-29', '08:00:00', '08:10:00', 1.5, 6, 2, 4.8, 5.2, 4.8), 
                                                                                                                                 (9, '2020-01-29', '08:15:00', '08:25:00', 1.6, 5, 2, 4.5, 5.1, 4.8), (10, '2020-01-29', '08:15:00', '08:25:00', 2, 6, 2, 4.6, 5, 4.8), (13, '2020-01-29', '08:15:00', '08:25:00', 1.9, 1, 2, 4.7, 5.1, 4.8),
                                                                                                                                 (11, '2020-01-29', '08:30:00', '08:40:00', 2.1, 5, 2, 4.7, 4.9, 4.8), (12, '2020-01-29', '08:30:00', '08:40:00', 2, 6, 3, 7, 6, 4.8), 
                                                                                                                                 (16, '2020-01-29', '08:15:00', '08:25:00', 3, 2, 4, 4.5, 3.3, 4.9), (17, '2020-01-29', '08:15:00', '08:25:00', 3, 3, 4, 4.5, 3.3, 4.9), (19, '2020-01-29', '08:15:00', '08:25:00', 3.2, 4, 4, 4.4, 3.1, 4.9),
                                                                                                                                 (1, '2020-01-30', '08:00:00', '08:10:00', 5, 1, 1, 3.7, 2.9, 4.9), (2, '2020-01-30', '08:00:00', '08:10:00', 4.5, 2, 1, 3.8, 3, 4.9), (3, '2020-01-30', '08:00:00', '08:10:00', 5.2, 3, 1, 3.7, 2.8, 4.9), (4, '2020-01-30', '08:00:00', '08:10:00', 5, 4, 1, 3.7, 2.9, 4.9),
                                                                                                                                 (7, '2020-01-30', '08:00:00', '08:10:00', 1.8, 5, 2, 4.6, 5, 4.8), (8, '2020-01-30', '08:00:00', '08:10:00', 1.5, 6, 2, 4.8, 5.2, 4.8), 
                                                                                                                                 (9, '2020-01-30', '08:15:00', '08:25:00', 1.6, 5, 2, 4.5, 5.1, 4.8), (10, '2020-01-30', '08:15:00', '08:25:00', 2, 6, 2, 4.6, 5, 4.8), (13, '2020-01-30', '08:15:00', '08:25:00', 1.9, 1, 2, 4.7, 5.1, 4.8),
                                                                                                                                 (11, '2020-01-30', '08:30:00', '08:40:00', 2.1, 5, 2, 4.7, 4.9, 4.8), (12, '2020-01-30', '08:30:00', '08:40:00', 2, 6, 3, 7, 6, 4.8), 
                                                                                                                                 (16, '2020-01-30', '08:15:00', '08:25:00', 3, 2, 4, 4.5, 3.3, 4.9), (17, '2020-01-30', '08:15:00', '08:25:00', 3, 3, 4, 4.5, 3.3, 4.9), (19, '2020-01-30', '08:15:00', '08:25:00', 3.2, 4, 4, 4.4, 3.1, 4.9),
                                                                                                                                 (1, '2020-01-31', '08:00:00', '08:10:00', 5, 1, 1, 3.7, 2.9, 4.9), (2, '2020-01-31', '08:00:00', '08:10:00', 4.5, 2, 1, 3.8, 3, 4.9), (3, '2020-01-31', '08:00:00', '08:10:00', 5.2, 3, 1, 3.7, 2.8, 4.9), (4, '2020-01-31', '08:00:00', '08:10:00', 5, 4, 1, 3.7, 2.9, 4.9),
                                                                                                                                 (7, '2020-01-31', '08:00:00', '08:10:00', 1.8, 5, 2, 4.6, 5, 4.8), (8, '2020-01-31', '08:00:00', '08:10:00', 1.5, 6, 2, 4.8, 5.2, 4.8), 
                                                                                                                                 (9, '2020-01-31', '08:15:00', '08:25:00', 1.6, 5, 2, 4.5, 5.1, 4.8), (10, '2020-01-31', '08:15:00', '08:25:00', 2, 6, 2, 4.6, 5, 4.8), (13, '2020-01-31', '08:15:00', '08:25:00', 1.9, 1, 2, 4.7, 5.1, 4.8),
                                                                                                                                 (11, '2020-01-31', '08:30:00', '08:40:00', 2.1, 5, 2, 4.7, 4.9, 4.8), (12, '2020-01-31', '08:30:00', '08:40:00', 2, 6, 3, 7, 6, 4.8), 
                                                                                                                                 (16, '2020-01-31', '08:15:00', '08:25:00', 3, 2, 4, 4.5, 3.3, 4.9), (17, '2020-01-31', '08:15:00', '08:25:00', 3, 3, 4, 4.5, 3.3, 4.9), (19, '2020-01-31', '08:15:00', '08:25:00', 3.2, 4, 4, 4.4, 3.1, 4.9);
                                                                                                                                 
                                                                                                                                 
;
COMMIT;

-- ------------------------------------
-- Records of 'Laboratorio'
-- ------------------------------------
BEGIN;
INSERT INTO `Laboratorio` (Agriturismo) VALUES ('Il Noce'), ('Il Noce'), ('Il Noce');
COMMIT;

-- ------------------------------------
-- Records of 'Cantina'
-- ------------------------------------
BEGIN;
INSERT INTO `Cantina` (Agriturismo) VALUES ('Il Noce'), ('Il Noce');
COMMIT;

-- ------------------------------------
-- Records of 'Dipendente'
-- ------------------------------------
BEGIN;
INSERT INTO `Dipendente` (Laboratorio) VALUES (1),(1),(1),(1),(1),
                                              (2),(2),(2),(2),(2),
                                              (3),(3),(3),(3),(3);
COMMIT;

-- ------------------------------------
-- Records of 'TipologiaFormaggio'
-- ------------------------------------
BEGIN;
INSERT INTO `TipologiaFormaggio` (Nome, TipoPasta, GradoDeperibilita) VALUES ('Pecorino', 'Semidura', 'Stabile'), ('Ricotta', 'Molle', 'Deperibile'), ('Belpaese', 'Molle', 'Semi-deperibile'), ('Grana', 'Dura', 'Stabile');
COMMIT;

-- ------------------------------------
-- Records of 'RicettaTestuale'
-- ------------------------------------
BEGIN;
INSERT INTO `RicettaTestuale` (TipologiaFormaggio, ZonaOrigine, Grasso, Proteine, Lattosio) VALUES ('Pecorino', 'Sardegna', 4.6, 5.1, 4.8), ('Pecorino', 'Pienza', 7, 6, 4.8), ('Ricotta', 'Italia', 3.7, 2.9, 4.9), ('Grana', 'Pianura Padana', 4.4, 3.1, 4.9);
COMMIT;

-- ------------------------------------
-- Records of 'FaseTestuale'
-- ------------------------------------
BEGIN;
INSERT INTO `FaseTestuale` (TipologiaFormaggio, OrigineRicetta, NumeroProgressivo, Durata, TemperaturaLatte, TempoRiposo, TemperaturaAmbiente) VALUES ('Pecorino', 'Sardegna', 1, 10, 39, 0, 21), ('Pecorino', 'Sardegna', 2, 40, 39, 40, 21), ('Pecorino', 'Sardegna', 3, 20, 28, 0, 21), ('Pecorino', 'Sardegna', 4, 1440, 21, 1440, 21),
																																					  ('Pecorino', 'Pienza', 1, 15, 38, 0, 21), ('Pecorino', 'Pienza', 2, 60, 38, 60, 21), ('Pecorino', 'Pienza', 3, 20, 28, 0, 21), ('Pecorino', 'Pienza', 4, 1440, 21, 1440, 21),
                                                                                                                                                      ('Ricotta', 'Italia', 1, 10, 40, 0, 21), ('Ricotta', 'Italia', 2, 40, 32, 0, 21), ('Ricotta', 'Italia', 3, 2440, 23, 2440, 23),
                                                                                                                                                      ('Grana', 'Pianura Padana', 1, 10, 39, 0, 21), ('Grana', 'Pianura Padana', 2, 2440, 21, 2440, 21);
COMMIT;

-- ------------------------------------
-- Records of 'Lotto'
-- ------------------------------------
BEGIN;
INSERT INTO `Lotto` (TipologiaFormaggio, OrigineRicetta, QuantitaLatteUsato, Silos, Laboratorio) VALUES ('Pecorino', 'Sardegna', 10, 2, 1), 
                                                                                                        ('Pecorino', 'Sardegna', 10, 2, 1), 
                                                                                                        ('Pecorino', 'Sardegna', 20, 2, 1),
                                                                                                        ('Pecorino', 'Pienza', 8, 3, 2),
                                                                                                        ('Grana', 'Pianura Padana', 30, 4, 2),
                                                                                                        ('Ricotta', 'Italia', 30, 1, 3),  
                                                                                                        ('Ricotta', 'Italia', 30, 1, 3);
-- usiamo l'update per attivare il trigger della analytics 3                                                                                                     
UPDATE Lotto SET DataProduzione = '2020-02-05', DataScadenza = '2022-02-05' WHERE Codice=1;
UPDATE Lotto SET DataProduzione = '2020-02-05', DataScadenza = '2022-02-05' WHERE Codice=2;
UPDATE Lotto SET DataProduzione = '2020-02-06', DataScadenza = '2022-02-06' WHERE Codice=3;
UPDATE Lotto SET DataProduzione = '2020-02-05', DataScadenza = '2022-02-05' WHERE Codice=4;
UPDATE Lotto SET DataProduzione = '2020-02-06', DataScadenza = '2024-02-06' WHERE Codice=5;
UPDATE Lotto SET DataProduzione = '2020-02-05', DataScadenza = '2022-02-09' WHERE Codice=6;
UPDATE Lotto SET DataProduzione = '2020-02-06', DataScadenza = '2022-02-10' WHERE Codice=7;
																					
COMMIT;

-- ------------------------------------
-- Records of 'StagionaturaPrevista'
-- ------------------------------------
BEGIN;
INSERT INTO `StagionaturaPrevista` (TipologiaFormaggio, OrigineRicetta, Temperatura, Umidita, Ventilazione, Giorni) VALUES ('Pecorino', 'Sardegna', 14, 85, 5, 360), ('Pecorino', 'Pienza', 14, 85, 5, 300), ('Grana', 'Pianura Padana', 14, 85, 5, 720);
COMMIT;

-- ------------------------------------
-- Records of 'FaseProduzione'
-- ------------------------------------
BEGIN;
INSERT INTO `FaseProduzione` (Lotto, NumeroProgressivo, Durata, TemperaturaLatte, TempoRiposo, TemperaturaAmbiente) VALUES (1, 1, 9, 39.8, 0, 21), (1, 2, 30, 40, 30, 21), (1, 3, 15, 27, 0, 21), (1, 4, 1440, 21, 1440, 21),
                                                                                                                           (2, 1, 8, 40, 0, 21), (2, 2, 35, 40.2, 35, 21), (2, 3, 14, 27.5, 0, 21), (2, 4, 1440, 21, 1440, 21),
                                                                                                                           (3, 1, 10, 38.7, 0, 21), (3, 2, 36, 39.8, 36, 21), (3, 3, 19, 28, 0, 21), (3, 4, 1440, 21, 1440, 21),
                                                                                                                           (4, 1, 14, 38.5, 0, 21), (4, 2, 57, 38.3, 57, 21), (4, 3, 20, 28, 0, 21), (4, 4, 1440, 21, 1440, 21),
                                                                                                                           (5, 1, 9, 39.5, 0, 21), (5, 2, 2440, 21, 2440, 21),
                                                                                                                           (6, 1, 9, 40, 0, 21), (6, 2, 44, 31, 0, 21), (6, 3, 2440, 22, 2440, 22),
                                                                                                                           (7, 1, 9, 40, 0, 21), (7, 2, 44, 30, 0, 21), (7, 3, 2440, 22, 2440, 22);
COMMIT;


-- ------------------------------------
-- Records of 'UnitaDiProdotto'
-- ------------------------------------
BEGIN;
INSERT INTO `UnitaDiProdotto` (Codice, Lotto, Peso) VALUES (1, 1, 1.5), (2, 1, 1.6), (3, 1, 1.7), (4, 1, 1.4), (5, 1, 1.5),
                                                           (1, 2, 1.4), (2, 2, 1.4), (3, 2, 1.8), (4, 2, 1.8), (5, 2, 1.5),
                                                           (1, 3, 1.6), (2, 3, 1.6), (3, 3, 1.7), (4, 3, 1.3), (5, 3, 1.5), (6, 3, 1.8), (7, 3, 1.6), (8, 3, 1.7), (9, 3, 1.4), (10, 3, 1.3),
                                                           (1, 4, 1.8), (2, 4, 1.7), (3, 4, 1.9), (4, 4, 1.8),
                                                           (1, 5, 2.8), (2, 5, 2.6), (3, 5, 2.8), (4, 5, 3), (5, 5, 3.1), (6, 5, 2.7), (7, 5, 2.9), (8, 5, 2.8), (9, 5, 2.8), (10, 5, 2.7),
                                                           (1, 6, 2.5), (2, 6, 2.6), (3, 6, 2.6), (4, 6, 2.7), (5, 6, 2.5), (6, 6, 2.5), (7, 6, 2.5),
                                                           (1, 7, 2.7), (2, 7, 2.6), (3, 7, 2.4), (4, 7, 2.5), (5, 7, 2.8), (6, 7, 2.6), (7, 7, 2.4);
COMMIT;

-- -------------------------------------
-- Records of 'Scaffale' and 'Posizione'
-- -------------------------------------
DROP PROCEDURE IF EXISTS InserimentoPosizioni;
DELIMITER $$
CREATE PROCEDURE InserimentoPosizioni(IN _numScaffali INT,
									  IN _numPosizioniScaffale INT)
BEGIN
  DECLARE i int DEFAULT 1;
  DECLARE j int DEFAULT 1;
  WHILE (i < _numScaffali + 1) DO 
    INSERT INTO `Scaffale`() VALUES ();    
    WHILE (j < _numPosizioniScaffale + 1) DO 
      INSERT INTO `Posizione`(Numero, Scaffale) VALUES (j, i);
       SET j = j + 1;
    END WHILE;    
    SET i = i + 1; 
	SET j = 1; 
  END WHILE;
END $$
DELIMITER ;
BEGIN;
CALL InserimentoPosizioni(20, 15);
COMMIT;

-- ------------------------------------
-- Records of 'Magazzino'
-- ------------------------------------
BEGIN;
INSERT INTO `Magazzino` (Agriturismo) VALUES ('Il Noce'), ('Il Noce');
COMMIT;

-- ------------------------------------
-- Records of 'OrganizzatoIn'
-- ------------------------------------
BEGIN;
INSERT INTO `OrganizzatoIn` (Magazzino, Scaffale) VALUES (1, 1), (1, 2), (1, 3), (1, 4), 
                                                         (2, 5), (2, 6), (2, 7), (2, 8);
COMMIT;

-- ------------------------------------
-- Records of 'OrganizzataIn'
-- ------------------------------------
BEGIN;
INSERT INTO `OrganizzataIn` (Cantina, Scaffale) VALUES (1, 9), (1, 10), (1, 11), (1, 12), (1, 13), (1, 14),
                                                       (2, 15), (2, 16), (2, 17), (2, 18), (2, 19), (2, 20);
COMMIT;

-- ------------------------------------
-- Records of 'ParametriAmbiente'
-- ------------------------------------
BEGIN;
INSERT INTO `ParametriAmbiente` (Cantina, Data, Temperatura, Umidita, Ventilazione) VALUES (1, '2020-01-31', 13.8, 85, 5), (2, '2020-01-31', 13.8, 85, 5),
                                                                                           (1, '2020-02-01', 14.1, 85, 5), (2, '2020-02-01', 14.1, 85, 5),
                                                                                           (1, current_date(), 14.1, 86, 5), (2, current_date(), 13.8, 85, 6);
COMMIT;


-- ------------------------------------
-- Records of 'Stoccaggio'
-- ------------------------------------
  -- Gestito dalla operazione 2
BEGIN;

CALL StoccaggioCantina(1,1);
CALL StoccaggioCantina(2,1);
CALL StoccaggioCantina(3,1);
CALL StoccaggioCantina(4,1);
CALL StoccaggioCantina(5,1);

CALL StoccaggioMagazzino(6,1);
CALL StoccaggioMagazzino (7,1);

COMMIT;

-- ------------------------------------
-- Records of 'Letto'
-- ------------------------------------
BEGIN;
INSERT INTO `Letto` (Piazze) VALUES (1), (2), (1), (2), (2), (2), (1), (2), (1), (2), (1);
COMMIT;

-- ------------------------------------
-- Records of 'Semplice'
-- ------------------------------------
BEGIN; 
INSERT INTO `Semplice` (Agriturismo, Tariffa, Letto) VALUES ('Il Noce', 50.00, 1),  ('Il Noce', 60.00, 2), ('Il Noce', 50.00, 3), ('Il Noce', 60.00, 4), ('Il Noce', 60.00, 5);
COMMIT;

-- ------------------------------------
-- Records of 'Suite'
-- ------------------------------------
BEGIN;
INSERT INTO `Suite` (Agriturismo, Tariffa) VALUES ('Il Noce', 100), ('Il Noce', 100), ('Il Noce', 100);
COMMIT;

-- ------------------------------------
-- Records of 'ArredoSuite'
-- ------------------------------------
BEGIN;
INSERT INTO `ArredoSuite` (Suite, Letto) VALUES (1, 6), (1, 7),
												(2, 8), (2, 9),
                                                (3, 10), (3, 11);
COMMIT;

-- ------------------------------------
-- Records of 'Servizio'
-- ------------------------------------                                                                                     
BEGIN;
INSERT INTO `Servizio` (Tipo, Costo) VALUES ('Sauna', 25), ('Fitness', 8), ('Piscina', 5), ('Massaggio', 25);
COMMIT;   

-- ------------------------------------
-- Records of 'Cliente', 'Documento', 'Account'
-- ------------------------------------
BEGIN;
-- Inserimento clienti senza account
INSERT INTO `Cliente`(CodiceMetodo, MetodoPagamento) VALUES (1113, 'PayPal');
-- Inserimento dei dati dei clienti registrati
CALL InserimentoClienteRegistrato('CartaDiCredito', 1111, '1A1111', 'Santippe', 'Disocrate', 'santippe.disocrate@gmail.com', 'santisoc', 'Atene', 'DeiDialoghi', 5, 52034);
CALL InserimentoClienteRegistrato('CartaDiCredito', 1112, '1A1112', 'Parmenide', 'DiElea', 'parmenide.dielea@gmail.com', 'Lesseree', 'Atene', 'DeiDialoghi', 6, 52034);
COMMIT;

-- ------------------------------------
-- Records of 'Prenotazione'
-- ------------------------------------
BEGIN;
INSERT INTO `Prenotazione` (Cliente, DataPrenotazione, OraPrenotazione, DataPartenza, DataArrivo) VALUES (1112, '2020-01-15', '15:35:00', '2020-05-23', '2020-05-16'),
																										 (1111, '2019-12-18', '16:29:00', '2020-05-25', '2020-05-15'),
                                                                                                         (1113, '2020-01-03', '10:00:00', '2020-05-27', '2020-05-20');
COMMIT; 

-- ------------------------------------
-- Records of 'RiservazioneSemplice'
-- ------------------------------------
BEGIN;
INSERT INTO `RiservazioneSemplice` (Semplice, Cliente, DataPrenotazione, OraPrenotazione) VALUES (1, 1111, '2019-12-18', '16:29:00'),
																								 (2, 1111, '2019-12-18', '16:29:00'),
                                                                                                 (3, 1113, '2020-01-03', '10:00:00');
COMMIT;

-- ------------------------------------
-- Records of 'RiservazioneSuite'
-- ------------------------------------
BEGIN;
INSERT INTO `RiservazioneSuite` (Suite, Cliente, DataPrenotazione, OraPrenotazione) VALUES (1, 1112, '2020-01-15', '15:35:00');
COMMIT;   

-- ------------------------------------
-- Records of 'Extra'
-- ------------------------------------
BEGIN;
INSERT INTO `Extra` (Suite, DataInizio, Servizio, DataFine) VALUES (1, '2020-05-17', 'Massaggio', '2020-05-20'),
																   (1, '2020-05-17', 'Piscina', '2020-05-22'),
																   (1, '2020-05-17', 'Sauna', '2020-05-17'),
                                                                   (1, '2020-05-17', 'Fitness', '2020-05-20');
COMMIT;	

-- ------------------------------------
-- Records of 'Pagamento'
-- ------------------------------------
BEGIN;
INSERT INTO `Pagamento` (Data, Ora, Cliente, DataPrenotazione, OraPrenotazione, Metodo, CodiceCarta, Importo) VALUES ('2020-05-23', '08:30:00', 1112, '2020-01-15', '15:35:00', 'CartaDiCredito', 1112, 887),
																													 ('2020-05-25', '09:02:00', 1111, '2019-12-18', '16:29:00', 'CartaDiCredito', 1111, 1100),
                                                                                                                     ('2020-06-07', '10:00:00', 1113, '2020-01-03', '10:00:00', 'Contanti', NULL, 175);
CALL CaparraNoAccount( 1113, '2020-01-03', '10:00:00');
COMMIT;

-- ------------------------------------
-- Records of 'Guida'
-- ------------------------------------
BEGIN;
INSERT INTO `Guida` (Nome, Cognome) VALUES ('Dante','Alighieri'), ('Marco Tullio','Cicerone');
COMMIT;

-- ------------------------------------
-- Records of 'Escursione'
-- ------------------------------------
BEGIN;
INSERT INTO `Escursione` (Data, OraInizio, Guida) VALUES ('2020-01-20', '08:30:00', 1), ('2020-02-07', '10:00:00', 2);
COMMIT;

-- ------------------------------------
-- Records of 'PrenotazioneEscursione'
-- ------------------------------------
BEGIN;
INSERT INTO `PrenotazioneEscursione` (Cliente, Escursione, Data, Ora) VALUES (1112,1,'2020-01-18', '08:00:00'), (1112,2,'2020-02-02', '10:00:00'),
																			 (1113,1,'2020-01-17', '08:30:00'),
																												(1111,2,'2020-02-01', '16:00:00');
COMMIT;

-- ------------------------------------
-- Records of 'Area'
-- ------------------------------------
BEGIN;
INSERT INTO `Area` (Agriturismo) VALUES ('Il Noce'), ('Il Noce'), ('Il Noce'), ('Il Noce'), ('Il Noce');
COMMIT;

-- ------------------------------------
-- Records of 'Sosta'
-- ------------------------------------
BEGIN;
INSERT INTO `Sosta` (Escursione, OraArrivo, Durata, Area) VALUES (1, '09:00:00', 15, 1), (1, '09:25:00', 25, 2), (1, '10:00:00', 15, 3), (1, '10:30:00', 20, 4), (1, '11:00:00', 30, 5),
                                                                 (2, '10:30:00', 15, 1), (2, '11:00:00', 20, 5), (2, '11:40:00', 15, 1), (2, '12:25:00', 20, 4), (2, '13:15:00', 45, 5);
COMMIT;