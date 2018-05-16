INSERT INTO client
SET name = 'Client', last_name = 'Client', id_number = 'sdaafgasdfavbd354321', sex = 1, birth_day = 87091200;
INSERT INTO client
SET name = 'Client', last_name = 'Client', id_number = 'sdaafgasdfavbd354322', sex = 1, birth_day = 87091200;
INSERT INTO client
SET name = 'Client', last_name = 'Client', id_number = 'sdaafgasdfavbd354323', sex = 1, birth_day = 87091200;
INSERT INTO client
SET name = 'Client', last_name = 'Client', id_number = 'sdaafgasdfavbd354324', sex = 1, birth_day = 87091200;
INSERT INTO client
SET name = 'Client', last_name = 'Client', id_number = 'sdaafgasdfavbd354325', sex = 1, birth_day = 87091200;

INSERT INTO contract
SET client_id = 1, account_type_id=1, amount=500.00,begin_at=1520985600, end_at=1552521600;
INSERT INTO contract
SET client_id = 2, account_type_id=1, amount=1500.00,begin_at=1522454400, end_at=1553990400;
INSERT INTO contract
SET client_id = 3, account_type_id=1, amount=15000.00,begin_at=1519862400, end_at=1551398400;
INSERT INTO contract
SET client_id = 4, account_type_id=1, amount=5000.00,begin_at=1515628800, end_at=1547424000;
INSERT INTO contract
SET client_id = 5, account_type_id=1, amount=5500.00,begin_at=1517443200, end_at=1548979200;
INSERT INTO contract
SET client_id = 6, account_type_id=1, amount=5500.00,begin_at=1523836800, end_at=1555372800;

INSERT INTO conditions
SET contract_id = 1, calculation_id=1, percent=0.20;
INSERT INTO conditions
SET contract_id = 2, calculation_id=1, percent=0.195;
INSERT INTO conditions
SET contract_id = 3, calculation_id=1, percent=0.21;
INSERT INTO conditions
SET contract_id = 4, calculation_id=1, percent=0.22;
INSERT INTO conditions
SET contract_id = 5, calculation_id=1, percent=0.20;
INSERT INTO conditions
SET contract_id = 6, calculation_id=1, percent=0.100;
