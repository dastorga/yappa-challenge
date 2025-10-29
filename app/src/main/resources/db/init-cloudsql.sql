-- Script de inicialización para Cloud SQL PostgreSQL
-- Yappa Challenge DevOps

-- Crear tabla para logs de actividad
CREATE TABLE IF NOT EXISTS activity_logs (
    id BIGSERIAL PRIMARY KEY,
    endpoint VARCHAR(500) NOT NULL,
    method VARCHAR(10) NOT NULL,
    user_agent TEXT,
    remote_ip VARCHAR(45),
    response_status INTEGER,
    execution_time_ms BIGINT,
    request_body TEXT,
    response_body TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_activity_logs_endpoint ON activity_logs(endpoint);
CREATE INDEX IF NOT EXISTS idx_activity_logs_method ON activity_logs(method);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_response_status ON activity_logs(response_status);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at
DROP TRIGGER IF EXISTS update_activity_logs_updated_at ON activity_logs;
CREATE TRIGGER update_activity_logs_updated_at
    BEFORE UPDATE ON activity_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insertar datos de ejemplo para testing
INSERT INTO activity_logs (endpoint, method, user_agent, remote_ip, response_status, execution_time_ms)
VALUES 
    ('/', 'GET', 'Mozilla/5.0 (Test)', '10.1.0.1', 200, 45),
    ('/api/info', 'GET', 'curl/7.68.0', '10.1.0.2', 200, 120),
    ('/api/echo', 'POST', 'PostmanRuntime/7.32.2', '10.1.0.3', 200, 89),
    ('/actuator/health', 'GET', 'GoogleHC/1.0', '10.1.0.4', 200, 12)
ON CONFLICT DO NOTHING;

-- Verificar que la tabla se creó correctamente
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'activity_logs'
ORDER BY ordinal_position;