// Repositorios para persistencia del módulo learning_passport

use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;
use chrono::{DateTime, Utc};

use crate::domain::{
    LearningInteraction, LifeLearningPassport, LearningPassportId, 
    LearningInteractionId, LearningPassportEvent
};

pub struct LearningPassportRepository {
    pool: PgPool,
}

impl LearningPassportRepository {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
    
    /// Crear un nuevo pasaporte de aprendizaje
    pub async fn create_passport(&self, passport: &LifeLearningPassport) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO learning_passports (
                id, user_address, humanity_proof_key, created_at, updated_at, blockchain_hash
            ) VALUES ($1, $2, $3, $4, $5, $6)
            "#,
            passport.id.0,
            passport.user_address,
            passport.humanity_proof_key,
            passport.created_at,
            passport.updated_at,
            passport.blockchain_hash
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    /// Obtener pasaporte por ID
    pub async fn get_passport_by_id(&self, passport_id: &LearningPassportId) -> Result<Option<LifeLearningPassport>> {
        let passport_row = sqlx::query!(
            r#"
            SELECT id, user_address, humanity_proof_key, created_at, updated_at, blockchain_hash
            FROM learning_passports
            WHERE id = $1
            "#,
            passport_id.0
        )
        .fetch_optional(&self.pool)
        .await?;
        
        if let Some(row) = passport_row {
            // Obtener interacciones asociadas
            let interactions = self.get_interactions_by_passport_id(passport_id).await?;
            
            let passport = LifeLearningPassport {
                id: LearningPassportId(row.id),
                user_address: row.user_address,
                humanity_proof_key: row.humanity_proof_key,
                interactions,
                created_at: row.created_at,
                updated_at: row.updated_at,
                blockchain_hash: row.blockchain_hash,
            };
            
            Ok(Some(passport))
        } else {
            Ok(None)
        }
    }
    
    /// Obtener pasaporte por dirección de usuario
    pub async fn get_passport_by_user_address(&self, user_address: &str) -> Result<Option<LifeLearningPassport>> {
        let passport_row = sqlx::query!(
            r#"
            SELECT id, user_address, humanity_proof_key, created_at, updated_at, blockchain_hash
            FROM learning_passports
            WHERE user_address = $1
            "#,
            user_address
        )
        .fetch_optional(&self.pool)
        .await?;
        
        if let Some(row) = passport_row {
            let passport_id = LearningPassportId(row.id);
            let interactions = self.get_interactions_by_passport_id(&passport_id).await?;
            
            let passport = LifeLearningPassport {
                id: passport_id,
                user_address: row.user_address,
                humanity_proof_key: row.humanity_proof_key,
                interactions,
                created_at: row.created_at,
                updated_at: row.updated_at,
                blockchain_hash: row.blockchain_hash,
            };
            
            Ok(Some(passport))
        } else {
            Ok(None)
        }
    }
    
    /// Actualizar pasaporte
    pub async fn update_passport(&self, passport: &LifeLearningPassport) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE learning_passports
            SET updated_at = $1, blockchain_hash = $2
            WHERE id = $3
            "#,
            passport.updated_at,
            passport.blockchain_hash,
            passport.id.0
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    /// Agregar interacción de aprendizaje
    pub async fn add_interaction(&self, interaction: &LearningInteraction) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO learning_interactions (
                id, passport_id, actor, verb, object, result, context, 
                timestamp, humanity_proof_key, signature, stored_in_blockchain
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            "#,
            interaction.id.0,
            interaction.passport_id.0,
            interaction.actor,
            interaction.verb,
            interaction.object,
            serde_json::to_value(&interaction.result)?,
            serde_json::to_value(&interaction.context)?,
            interaction.timestamp,
            interaction.humanity_proof_key,
            interaction.signature,
            interaction.stored_in_blockchain
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    /// Obtener interacciones por ID de pasaporte
    pub async fn get_interactions_by_passport_id(&self, passport_id: &LearningPassportId) -> Result<Vec<LearningInteraction>> {
        let rows = sqlx::query!(
            r#"
            SELECT id, passport_id, actor, verb, object, result, context,
                   timestamp, humanity_proof_key, signature, stored_in_blockchain
            FROM learning_interactions
            WHERE passport_id = $1
            ORDER BY timestamp ASC
            "#,
            passport_id.0
        )
        .fetch_all(&self.pool)
        .await?;
        
        let mut interactions = Vec::new();
        
        for row in rows {
            let interaction = LearningInteraction {
                id: LearningInteractionId(row.id),
                passport_id: LearningPassportId(row.passport_id),
                actor: row.actor,
                verb: row.verb,
                object: row.object,
                result: if let Some(result_json) = row.result {
                    serde_json::from_value(result_json)?
                } else {
                    None
                },
                context: if let Some(context_json) = row.context {
                    serde_json::from_value(context_json)?
                } else {
                    None
                },
                timestamp: row.timestamp,
                humanity_proof_key: row.humanity_proof_key,
                signature: row.signature,
                stored_in_blockchain: row.stored_in_blockchain,
            };
            
            interactions.push(interaction);
        }
        
        Ok(interactions)
    }
    
    /// Marcar interacción como almacenada en blockchain
    pub async fn mark_interaction_stored_in_blockchain(&self, interaction_id: &LearningInteractionId) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE learning_interactions
            SET stored_in_blockchain = true
            WHERE id = $1
            "#,
            interaction_id.0
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    /// Obtener interacciones pendientes de sincronizar con blockchain
    pub async fn get_pending_blockchain_interactions(&self) -> Result<Vec<LearningInteraction>> {
        let rows = sqlx::query!(
            r#"
            SELECT id, passport_id, actor, verb, object, result, context,
                   timestamp, humanity_proof_key, signature, stored_in_blockchain
            FROM learning_interactions
            WHERE stored_in_blockchain = false
            ORDER BY timestamp ASC
            "#,
        )
        .fetch_all(&self.pool)
        .await?;
        
        let mut interactions = Vec::new();
        
        for row in rows {
            let interaction = LearningInteraction {
                id: LearningInteractionId(row.id),
                passport_id: LearningPassportId(row.passport_id),
                actor: row.actor,
                verb: row.verb,
                object: row.object,
                result: if let Some(result_json) = row.result {
                    serde_json::from_value(result_json)?
                } else {
                    None
                },
                context: if let Some(context_json) = row.context {
                    serde_json::from_value(context_json)?
                } else {
                    None
                },
                timestamp: row.timestamp,
                humanity_proof_key: row.humanity_proof_key,
                signature: row.signature,
                stored_in_blockchain: row.stored_in_blockchain,
            };
            
            interactions.push(interaction);
        }
        
        Ok(interactions)
    }
}
