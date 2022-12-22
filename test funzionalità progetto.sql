 -- test per la funzione 1
-- vedere inserimenti dei records della tabella Cliente
select * from cliente c inner join `account` a on c.codicemetodo = a.cliente natural join indirizzo i;
CALL InserimentoClienteRegistrato('CartaDiCredito', 1234, 'Pr0v4', 'Ippaso', 'Di Metaponto', 'ippaso.dimetaponto@gmail.com', 'MPit', 'Samo', 'DellaTetractis', 1, 1414);
select * from cliente c inner join `account` a on c.codicemetodo = a.cliente natural join indirizzo i;

 -- test per la funzione 2 
select s.*, l.TipologiaFormaggio, l.OrigineRicetta, l.Cantina from stoccaggio s inner join lotto l on l.codice = s.lotto;
-- reset degli stoccaggi
truncate stoccaggio;
CALL StoccaggioCantina(1,1);
CALL StoccaggioCantina(2,1);
CALL StoccaggioCantina(3,1);
CALL StoccaggioCantina(4,1);
CALL StoccaggioCantina(5,1);
CALL StoccaggioMagazzino(6,1);
CALL StoccaggioMagazzino(7,1);
-- spostamento dei lotti dalla cantina in magazzino
CALL StoccaggioMagazzino(1,1);
CALL StoccaggioMagazzino(2,1);
CALL StoccaggioMagazzino(3,1);
CALL StoccaggioMagazzino(4,1);
CALL StoccaggioMagazzino(5,1);  -- poichè nel magazzino 1 non ci sono più scaffali liberi, la procedura ci avverte. testare dunque lo stoccaggio nel magazzino 2.
-- si noti che lo stoccaggio è dinamico: le unità vengono posizionate secondo una precisa politica
delete from stoccaggio where lotto = 2; -- faccio la delete perchè non posso stagionare piu volte lo stesso lotto!
CALL StoccaggioCantina(2,1);

 -- test per la funzione 3
 select ft.*, fp.* from faseproduzione fp inner join lotto l on fp.lotto = l.codice inner join fasetestuale ft on ft.OrigineRicetta = l.OrigineRicetta and ft.TipologiaFormaggio = l.TipologiaFormaggio and ft.numeroprogressivo = fp.numeroprogressivo where fp.lotto = 1 and fp.numeroprogressivo = 1;
CALL ScostamentoFaseProduzione(1,1, @durata, @templ, @riposo, @tempa); select @durata, @templ, @riposo, @tempa;

 -- test per la funzione 4
select * from pasto;
select * from foraggio;
call RimanenzaPasto('2020-01-23', '12:00:00', 1, @risultato);
select @risultato;

 -- test per la funzione 5
select  l.codice as Lotto, sp.*, pa.* from lotto l inner join parametriambiente pa on l.cantina = pa.cantina inner join stagionaturaprevista sp on l.tipologiaformaggio = sp.tipologiaformaggio and l.originericetta = sp.originericetta where pa.data = '2020-02-02';
CALL ControlloStagionatura (1, '2020-02-02');
select * from _ScostamentiStagionatura;

 -- test per la funzione 6
select * from AttivitaPascolo;
select * from UscitaPascolo;
call RitardoRientroAnimali('2020-01-31', '07:00:00', 1, 1);
select * from _animaliInRitardo;
call RitardoRientroAnimali('2020-01-31', '08:00:00', 1, 2);
select * from _animaliInRitardo;

 -- test per funzione 7
select * from semplice; select * from suite;
select * from prenotazione p natural join riservazionesemplice se;
select * from prenotazione p natural join riservazionesuite su;
CALL StanzeLibere('2020-05-20', '2020-06-05', 'Il Noce'); 
select * from _DisponibilitaPeriodo;

-- test per funzione 8
select * from prenotazione;
select CostoSoggiorno('2020-01-15','15:35:00', 1112);
select @costoSemplice; select @costoSuite; select @costoExtra;

 -- test per la analytics 1
call ComportamentoAnimali('2020-01-31', '07:00:00', 1, 1);

 -- test per la analytics 2
select * from log_lotti_prodotti;
CALL Refresh_QualitaProcesso(@esito);  -- in teoria sarebbe chiamata tramite event giornaliero
select * from Report_QualitaProcesso;

 -- test per la analytics 3
CALL RankLaboratori('2020-02-04','2020-02-06');