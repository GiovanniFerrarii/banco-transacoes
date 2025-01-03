USE BancoTransacoes;

-- Criação do banco de dados
CREATE DATABASE IF NOT EXISTS BancoTransacoes;
USE BancoTransacoes;

-- Tabela de Clientes
CREATE TABLE IF NOT EXISTS Clientes (
    ClienteID INT AUTO_INCREMENT PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    CPF CHAR(11) UNIQUE NOT NULL,
    DataNascimento DATE NOT NULL,
    Telefone VARCHAR(15),
    Email VARCHAR(100)
);

-- Tabela de Contas
CREATE TABLE IF NOT EXISTS Contas (
    ContaID INT AUTO_INCREMENT PRIMARY KEY,
    ClienteID INT NOT NULL,
    NumeroConta VARCHAR(10) UNIQUE NOT NULL,
    Saldo DECIMAL(15,2) DEFAULT 0.00,
    DataAbertura DATE NOT NULL,
    FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
);

-- Verificação e Criação da Tabela de Transações
DROP TABLE IF EXISTS Transacoes; -- Garante que a tabela será criada do zero
CREATE TABLE IF NOT EXISTS Transacoes (
    TransacaoID INT AUTO_INCREMENT PRIMARY KEY,
    ContaOrigemID INT,
    ContaDestinoID INT,
    TipoTransacao ENUM('Saque', 'Deposito', 'Transferencia') NOT NULL,
    Valor DECIMAL(15,2) NOT NULL,
    DataTransacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ContaOrigemID) REFERENCES Contas(ContaID),
    FOREIGN KEY (ContaDestinoID) REFERENCES Contas(ContaID)
);

-- Procedimento para Saque
DELIMITER $$
CREATE PROCEDURE RealizarSaque(IN p_ContaID INT, IN p_Valor DECIMAL(15,2))
BEGIN
    DECLARE v_SaldoAtual DECIMAL(15,2);

    SELECT Saldo INTO v_SaldoAtual FROM Contas WHERE ContaID = p_ContaID;

    IF v_SaldoAtual >= p_Valor THEN
        UPDATE Contas SET Saldo = Saldo - p_Valor WHERE ContaID = p_ContaID;
        INSERT INTO Transacoes (ContaOrigemID, TipoTransacao, Valor) VALUES (p_ContaID, 'Saque', p_Valor);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insuficiente para o saque';
    END IF;
END$$
DELIMITER ;

-- Procedimento para Depósito
DELIMITER $$
CREATE PROCEDURE RealizarDeposito(IN p_ContaID INT, IN p_Valor DECIMAL(15,2))
BEGIN
    UPDATE Contas SET Saldo = Saldo + p_Valor WHERE ContaID = p_ContaID;
    INSERT INTO Transacoes (ContaDestinoID, TipoTransacao, Valor) VALUES (p_ContaID, 'Deposito', p_Valor);
END$$
DELIMITER ;

-- Procedimento para Transferência
DELIMITER $$
CREATE PROCEDURE RealizarTransferencia(IN p_ContaOrigemID INT, IN p_ContaDestinoID INT, IN p_Valor DECIMAL(15,2))
BEGIN
    DECLARE v_SaldoAtual DECIMAL(15,2);

    SELECT Saldo INTO v_SaldoAtual FROM Contas WHERE ContaID = p_ContaOrigemID;

    IF v_SaldoAtual >= p_Valor THEN
        UPDATE Contas SET Saldo = Saldo - p_Valor WHERE ContaID = p_ContaOrigemID;
        UPDATE Contas SET Saldo = Saldo + p_Valor WHERE ContaID = p_ContaDestinoID;
        INSERT INTO Transacoes (ContaOrigemID, ContaDestinoID, TipoTransacao, Valor) 
        VALUES (p_ContaOrigemID, p_ContaDestinoID, 'Transferencia', p_Valor);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Saldo insuficiente para a transferência';
    END IF;
END$$
DELIMITER ;

-- Inserção de dados de teste

-- Inserir Cliente 1
INSERT INTO Clientes (Nome, CPF, DataNascimento, Telefone, Email) 
VALUES ('Teste Cliente', '12345678901', '1990-01-01', '11999999999', 'teste@cliente.com');

-- Inserir Conta para Cliente 1
INSERT INTO Contas (ClienteID, NumeroConta, Saldo, DataAbertura) 
VALUES (1, '00012345', 1000.00, '2025-01-01');

-- Inserir Cliente 2
INSERT INTO Clientes (Nome, CPF, DataNascimento, Telefone, Email) 
VALUES ('Novo Cliente', '98765432100', '1995-05-10', '11988887777', 'novocliente@exemplo.com');

-- Inserir Conta para Cliente 2
INSERT INTO Contas (ClienteID, NumeroConta, Saldo, DataAbertura) 
VALUES (2, '00054321', 500.00, '2025-01-01');

-- Realizar um depósito
CALL RealizarDeposito(1, 200.00);  -- Depósito de 200.00 na Conta 1

-- Realizar um saque
CALL RealizarSaque(1, 50.00);      -- Saque de 50.00 da Conta 1

-- Realizar uma transferência
CALL RealizarTransferencia(1, 2, 100.00);  -- Transferência de 100.00 de Conta 1 para Conta 2

-- Verificar as transações realizadas
SELECT * FROM Transacoes;  -- Verificar as transações









	
