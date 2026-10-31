// Entidades de dominio para el módulo learning_passport
// Gestiona tanto las interacciones de aprendizaje como los pasaportes de aprendizaje

use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LearningPassportId(pub Uuid);

impl LearningPassportId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LearningInteractionId(pub Uuid);

impl LearningInteractionId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

/// Interacción de aprendizaje atómica compatible con xAPI
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LearningInteraction {
    pub id: LearningInteractionId,
    pub passport_id: LearningPassportId,
    pub actor: String,           // Identificador del actor (usuario)
    pub verb: String,            // Acción realizada (ej: "completed", "attempted")
    pub object: String,          // Objeto de la interacción (curso, lección, etc.)
    pub result: Option<LearningResult>,
    pub context: Option<LearningContext>,
    pub timestamp: DateTime<Utc>,
    pub humanity_proof_key: String,  // Clave de verificación de humanidad
    pub signature: Option<String>,   // Firma Ed25519 de la interacción
    pub stored_in_blockchain: bool,  // Indica si ya está en Keikochain
}

/// Resultado de una interacción de aprendizaje
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LearningResult {
    pub success: bool,
    pub completion: Option<f64>,  // Porcentaje de completitud
    pub score: Option<f64>,       // Puntuación obtenida
    pub duration: Option<i64>,    // Duración en segundos
    pub response: Option<String>, // Respuesta del usuario
}

/// Contexto de una interacción de aprendizaje
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LearningContext {
    pub platform: String,        // Plataforma donde ocurrió
    pub language: String,        // Idioma de la interacción
    pub instructor: Option<String>, // Instructor o tutor
    pub group: Option<String>,   // Grupo o cohorte
    pub extensions: Option<serde_json::Value>, // Extensiones personalizadas
}

/// Life Learning Passport - Agregación de interacciones de aprendizaje
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LifeLearningPassport {
    pub id: LearningPassportId,
    pub user_address: String,    // Dirección blockchain del usuario
    pub humanity_proof_key: String, // Clave de verificación de humanidad
    pub interactions: Vec<LearningInteraction>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub blockchain_hash: Option<String>, // Hash del estado en blockchain
}

impl LifeLearningPassport {
    /// Agregar nueva interacción al pasaporte
    pub fn add_interaction(&mut self, interaction: LearningInteraction) {
        self.interactions.push(interaction);
        self.updated_at = Utc::now();
    }
    
    /// Obtener interacciones ordenadas cronológicamente
    pub fn get_interactions_chronological(&self) -> Vec<&LearningInteraction> {
        let mut interactions: Vec<&LearningInteraction> = self.interactions.iter().collect();
        interactions.sort_by(|a, b| a.timestamp.cmp(&b.timestamp));
        interactions
    }
    
    /// Calcular estadísticas del pasaporte
    pub fn get_statistics(&self) -> PassportStatistics {
        let total_interactions = self.interactions.len();
        let successful_interactions = self.interactions.iter()
            .filter(|i| i.result.as_ref().map(|r| r.success).unwrap_or(false))
            .count();
        let completion_rate = if total_interactions > 0 {
            (successful_interactions as f64 / total_interactions as f64) * 100.0
        } else {
            0.0
        };
        
        let total_duration: i64 = self.interactions.iter()
            .filter_map(|i| i.result.as_ref().and_then(|r| r.duration))
            .sum();
        
        PassportStatistics {
            total_interactions,
            successful_interactions,
            completion_rate,
            total_duration,
            last_activity: self.interactions.iter()
                .map(|i| i.timestamp)
                .max()
                .copied(),
        }
    }
}

/// Estadísticas del pasaporte de aprendizaje
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PassportStatistics {
    pub total_interactions: usize,
    pub successful_interactions: usize,
    pub completion_rate: f64,
    pub total_duration: i64,
    pub last_activity: Option<DateTime<Utc>>,
}

/// Eventos de dominio para learning_passport
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum LearningPassportEvent {
    PassportCreated {
        passport_id: LearningPassportId,
        user_address: String,
        timestamp: DateTime<Utc>,
    },
    InteractionAdded {
        passport_id: LearningPassportId,
        interaction_id: LearningInteractionId,
        timestamp: DateTime<Utc>,
    },
    PassportUpdated {
        passport_id: LearningPassportId,
        blockchain_hash: String,
        timestamp: DateTime<Utc>,
    },
}
