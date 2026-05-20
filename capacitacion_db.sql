-- ═══════════════════════════════════════════════════════════════
-- BASE DE DATOS: Compra Segura Auto – Plataforma de Capacitación
-- Compatible con: MySQL 8+ / MariaDB 10.6+
-- ═══════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS capacitacion_auto
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE capacitacion_auto;

-- ──────────────────────────────────────────
-- 1. USUARIOS
--    Registra a cada persona que comienza la capacitación.
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS usuarios (
  id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(100)    NOT NULL,
  apellido      VARCHAR(100)    NOT NULL,
  email         VARCHAR(255)    NOT NULL,
  fecha_registro DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ip_origen     VARCHAR(45)     NULL COMMENT 'IPv4 o IPv6 del usuario al registrarse',
  PRIMARY KEY (id),
  UNIQUE KEY uq_email (email)
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- 2. MÓDULOS
--    Catálogo fijo de los 5 módulos del curso.
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS modulos (
  id            TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden         TINYINT UNSIGNED NOT NULL,
  icono         VARCHAR(10)      NOT NULL,
  titulo        VARCHAR(200)     NOT NULL,
  descripcion   TEXT             NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_orden (orden)
) ENGINE=InnoDB;

-- Datos iniciales de los módulos
INSERT INTO modulos (orden, icono, titulo, descripcion) VALUES
(1, '🔍', 'Cómo verificar si la agencia existe',
    'Antes de señar o transferir cualquier dinero, chequeá que la agencia sea real y habilitada.'),
(2, '📄', 'Cómo descargar la constancia de ARCA',
    'Aprendé el proceso paso a paso para verificar la constancia de ARCA.'),
(3, '🚗', 'Checklist para cuando recibís el auto',
    'Revisión mecánica y documental al momento de la entrega pactada por contrato.'),
(4, '📝', 'El Formulario 08 y la documentación de entrega',
    'Lo que debe estar listo en la fecha de entrega pactada por contrato.'),
(5, '⚖️', 'Tus derechos como comprador',
    'La Ley 24.240 de Defensa del Consumidor te protege en cada compra.');

-- ──────────────────────────────────────────
-- 3. SESIONES
--    Cada vez que un usuario inicia la capacitación se crea una sesión.
--    Permite que el mismo email rehaga el curso y guarde historial.
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sesiones (
  id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  usuario_id      INT UNSIGNED    NOT NULL,
  fecha_inicio    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_fin       DATETIME        NULL     COMMENT 'NULL mientras la sesión está activa',
  estado          ENUM(
                    'en_curso',
                    'quiz_completado',
                    'certificado_emitido'
                  )               NOT NULL DEFAULT 'en_curso',
  PRIMARY KEY (id),
  KEY idx_usuario (usuario_id),
  CONSTRAINT fk_sesion_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- 4. PROGRESO DE MÓDULOS
--    Registra qué módulos completó el usuario en cada sesión.
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS progreso_modulos (
  id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  sesion_id       INT UNSIGNED    NOT NULL,
  modulo_id       TINYINT UNSIGNED NOT NULL,
  fecha_completado DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sesion_modulo (sesion_id, modulo_id),
  KEY idx_modulo (modulo_id),
  CONSTRAINT fk_progreso_sesion
    FOREIGN KEY (sesion_id) REFERENCES sesiones(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_progreso_modulo
    FOREIGN KEY (modulo_id) REFERENCES modulos(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- 5. PREGUNTAS DEL QUIZ
--    Catálogo de preguntas con la respuesta correcta.
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS preguntas_quiz (
  id              TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  orden           TINYINT UNSIGNED NOT NULL,
  enunciado       TEXT             NOT NULL,
  opcion_a        VARCHAR(500)     NOT NULL,
  opcion_b        VARCHAR(500)     NOT NULL,
  opcion_c        VARCHAR(500)     NOT NULL,
  opcion_d        VARCHAR(500)     NOT NULL,
  respuesta_correcta TINYINT UNSIGNED NOT NULL COMMENT '0=A, 1=B, 2=C, 3=D',
  feedback        TEXT             NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_orden (orden)
) ENGINE=InnoDB;

-- Datos de las 5 preguntas actuales
INSERT INTO preguntas_quiz (orden, enunciado, opcion_a, opcion_b, opcion_c, opcion_d, respuesta_correcta, feedback) VALUES
(1,
 '¿Cuál es el primer paso para verificar que una agencia existe legalmente?',
 'Buscarla en internet',
 'Pedir el CUIT y verificarlo en ARCA',
 'Por Página',
 'Preguntarle a conocidos',
 1,
 '✅ ¡Correcto! El CUIT verificado en ARCA es el primer paso fundamental. Internet o redes sociales son fáciles de falsificar.'),
(2,
 'Al firmar un contrato de financiación, ¿qué información debe estar siempre por escrito?',
 'Solo el precio total del auto',
 'La cuota, cantidad de cuotas, fecha de entrega y condiciones del plan',
 'Solo el nombre de la agencia',
 'El número de patente del auto',
 1,
 '✅ ¡Exacto! El contrato debe detallar la cuota exacta, cantidad de cuotas, fecha pactada de entrega y todas las condiciones. Nunca aceptes acuerdos solo verbales.'),
(3,
 '¿Qué es el Formulario 08 y para qué sirve?',
 'Es la factura de compra del auto',
 'Es la autorización de transferencia de titularidad del vehículo',
 'Es el libre deuda de patentes',
 'Es el certificado de VTV',
 1,
 '✅ ¡Muy bien! El Formulario 08 habilita el cambio de titular. Sin él, la compra no tiene validez legal.'),
(4,
 'Cuando llegás a retirar el auto en la fecha pactada, ¿qué hacés primero?',
 'Firmás la recepción y te lo llevás',
 'Revisás mecánicamente el auto y verificás que la documentación esté completa antes de firmar',
 'Pagás la última cuota sin revisar nada',
 'Confiás en que la agencia ya revisó todo',
 1,
 '✅ ¡Correcto! Revisá frenos, motor, luces, cubiertas, kilometraje y que toda la documentación (Formulario 08, título, libre deuda, VTV) esté en orden antes de firmar.'),
(5,
 'La agencia te dice "no te puedo dar factura pero el precio baja $200.000". ¿Qué hacés?',
 'Aceptás porque ahorrás dinero',
 'Pedís factura igual aunque cueste más',
 'Preguntás si pueden hacer un recibo informal',
 'Da igual, el contrato es suficiente',
 1,
 '✅ ¡Excelente! Sin factura no tenés respaldo legal, no podés reclamar garantía ni hacer trámites. El ahorro no vale el riesgo.');

-- ──────────────────────────────────────────
-- 6. RESPUESTAS DEL QUIZ
--    Almacena cada respuesta individual del usuario.
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS respuestas_quiz (
  id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  sesion_id       INT UNSIGNED    NOT NULL,
  pregunta_id     TINYINT UNSIGNED NOT NULL,
  opcion_elegida  TINYINT UNSIGNED NOT NULL COMMENT '0=A, 1=B, 2=C, 3=D',
  es_correcta     TINYINT(1)      NOT NULL,
  fecha_respuesta DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sesion_pregunta (sesion_id, pregunta_id),
  KEY idx_pregunta (pregunta_id),
  CONSTRAINT fk_resp_sesion
    FOREIGN KEY (sesion_id) REFERENCES sesiones(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_resp_pregunta
    FOREIGN KEY (pregunta_id) REFERENCES preguntas_quiz(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ──────────────────────────────────────────
-- 7. CERTIFICADOS
--    Uno por sesión aprobada (puntaje ≥ 60%).
-- ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS certificados (
  id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  sesion_id       INT UNSIGNED    NOT NULL,
  codigo          VARCHAR(30)     NOT NULL COMMENT 'Ej: CSA-2025-06-A3F9K2',
  puntaje         TINYINT UNSIGNED NOT NULL COMMENT 'Respuestas correctas',
  puntaje_total   TINYINT UNSIGNED NOT NULL COMMENT 'Total de preguntas',
  porcentaje      DECIMAL(5,2)    NOT NULL COMMENT '0.00 – 100.00',
  fecha_emision   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_sesion (sesion_id),
  UNIQUE KEY uq_codigo (codigo),
  CONSTRAINT fk_cert_sesion
    FOREIGN KEY (sesion_id) REFERENCES sesiones(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ══════════════════════════════════════════════════════════════
-- VISTAS ÚTILES
-- ══════════════════════════════════════════════════════════════

-- Vista: Resumen por usuario (última sesión)
CREATE OR REPLACE VIEW v_resumen_usuarios AS
SELECT
  u.id                                    AS usuario_id,
  u.nombre,
  u.apellido,
  u.email,
  u.fecha_registro,
  s.id                                    AS sesion_id,
  s.fecha_inicio,
  s.fecha_fin,
  s.estado,
  COUNT(DISTINCT pm.modulo_id)            AS modulos_completados,
  (SELECT COUNT(*) FROM modulos)          AS total_modulos,
  c.codigo                                AS nro_certificado,
  c.porcentaje                            AS puntaje_pct,
  c.fecha_emision                         AS fecha_certificado
FROM usuarios u
LEFT JOIN sesiones s
  ON s.usuario_id = u.id
LEFT JOIN progreso_modulos pm
  ON pm.sesion_id = s.id
LEFT JOIN certificados c
  ON c.sesion_id = s.id
GROUP BY u.id, s.id, c.id
ORDER BY s.fecha_inicio DESC;

-- Vista: Estadísticas globales del quiz
CREATE OR REPLACE VIEW v_stats_preguntas AS
SELECT
  pq.orden,
  pq.enunciado,
  COUNT(rq.id)                                     AS total_respuestas,
  SUM(rq.es_correcta)                              AS respuestas_correctas,
  ROUND(SUM(rq.es_correcta) / COUNT(rq.id) * 100, 1) AS pct_acierto
FROM preguntas_quiz pq
LEFT JOIN respuestas_quiz rq ON rq.pregunta_id = pq.id
GROUP BY pq.id
ORDER BY pq.orden;

-- ══════════════════════════════════════════════════════════════
-- STORED PROCEDURES
-- ══════════════════════════════════════════════════════════════

DELIMITER $$

-- SP: Registrar usuario y abrir sesión
DROP PROCEDURE IF EXISTS sp_iniciar_capacitacion $$
CREATE PROCEDURE sp_iniciar_capacitacion(
  IN p_nombre    VARCHAR(100),
  IN p_apellido  VARCHAR(100),
  IN p_email     VARCHAR(255),
  IN p_ip        VARCHAR(45),
  OUT p_sesion_id INT UNSIGNED
)
BEGIN
  DECLARE v_usuario_id INT UNSIGNED;

  -- Insertar o actualizar usuario (el email es único)
  INSERT INTO usuarios (nombre, apellido, email, ip_origen)
  VALUES (p_nombre, p_apellido, p_email, p_ip)
  ON DUPLICATE KEY UPDATE
    nombre   = VALUES(nombre),
    apellido = VALUES(apellido),
    ip_origen = VALUES(ip_origen);

  SET v_usuario_id = (SELECT id FROM usuarios WHERE email = p_email);

  -- Crear nueva sesión
  INSERT INTO sesiones (usuario_id) VALUES (v_usuario_id);
  SET p_sesion_id = LAST_INSERT_ID();
END $$

-- SP: Registrar módulo completado
DROP PROCEDURE IF EXISTS sp_completar_modulo $$
CREATE PROCEDURE sp_completar_modulo(
  IN p_sesion_id  INT UNSIGNED,
  IN p_modulo_id  TINYINT UNSIGNED
)
BEGIN
  INSERT IGNORE INTO progreso_modulos (sesion_id, modulo_id)
  VALUES (p_sesion_id, p_modulo_id);
END $$

-- SP: Guardar respuesta del quiz
DROP PROCEDURE IF EXISTS sp_guardar_respuesta $$
CREATE PROCEDURE sp_guardar_respuesta(
  IN p_sesion_id     INT UNSIGNED,
  IN p_pregunta_id   TINYINT UNSIGNED,
  IN p_opcion        TINYINT UNSIGNED
)
BEGIN
  DECLARE v_correcta TINYINT(1);
  SELECT respuesta_correcta = p_opcion INTO v_correcta
  FROM preguntas_quiz WHERE id = p_pregunta_id;

  INSERT INTO respuestas_quiz (sesion_id, pregunta_id, opcion_elegida, es_correcta)
  VALUES (p_sesion_id, p_pregunta_id, p_opcion, v_correcta)
  ON DUPLICATE KEY UPDATE
    opcion_elegida = VALUES(opcion_elegida),
    es_correcta    = VALUES(es_correcta),
    fecha_respuesta = CURRENT_TIMESTAMP;
END $$

-- SP: Emitir certificado si el puntaje ≥ 60%
DROP PROCEDURE IF EXISTS sp_emitir_certificado $$
CREATE PROCEDURE sp_emitir_certificado(
  IN  p_sesion_id  INT UNSIGNED,
  IN  p_codigo     VARCHAR(30),
  OUT p_exito      TINYINT(1)
)
BEGIN
  DECLARE v_correctas   TINYINT UNSIGNED;
  DECLARE v_total       TINYINT UNSIGNED;
  DECLARE v_pct         DECIMAL(5,2);

  SELECT
    SUM(es_correcta),
    COUNT(*),
    ROUND(SUM(es_correcta) / COUNT(*) * 100, 2)
  INTO v_correctas, v_total, v_pct
  FROM respuestas_quiz
  WHERE sesion_id = p_sesion_id;

  IF v_pct >= 60 THEN
    INSERT INTO certificados (sesion_id, codigo, puntaje, puntaje_total, porcentaje)
    VALUES (p_sesion_id, p_codigo, v_correctas, v_total, v_pct)
    ON DUPLICATE KEY UPDATE
      codigo        = VALUES(codigo),
      puntaje       = VALUES(puntaje),
      porcentaje    = VALUES(porcentaje),
      fecha_emision = CURRENT_TIMESTAMP;

    UPDATE sesiones SET estado = 'certificado_emitido', fecha_fin = CURRENT_TIMESTAMP
    WHERE id = p_sesion_id;

    SET p_exito = 1;
  ELSE
    UPDATE sesiones SET estado = 'quiz_completado' WHERE id = p_sesion_id;
    SET p_exito = 0;
  END IF;
END $$

DELIMITER ;

-- ══════════════════════════════════════════════════════════════
-- EJEMPLOS DE USO
-- ══════════════════════════════════════════════════════════════
/*
-- 1. Iniciar capacitación
CALL sp_iniciar_capacitacion('Juan', 'Pérez', 'juan@email.com', '190.0.1.2', @sesion);
SELECT @sesion;  -- guarda este ID en el frontend (localStorage / session)

-- 2. Completar módulos
CALL sp_completar_modulo(@sesion, 1);
CALL sp_completar_modulo(@sesion, 2);
-- ... hasta 5

-- 3. Guardar respuestas del quiz (una por pregunta)
CALL sp_guardar_respuesta(@sesion, 1, 1);
CALL sp_guardar_respuesta(@sesion, 2, 1);
CALL sp_guardar_respuesta(@sesion, 3, 1);
CALL sp_guardar_respuesta(@sesion, 4, 1);
CALL sp_guardar_respuesta(@sesion, 5, 1);

-- 4. Emitir certificado
CALL sp_emitir_certificado(@sesion, 'CSA-2025-06-A3F9K2', @ok);
SELECT @ok;  -- 1 = certificado emitido, 0 = puntaje insuficiente

-- 5. Consultar dashboard
SELECT * FROM v_resumen_usuarios LIMIT 20;
SELECT * FROM v_stats_preguntas;
*/
