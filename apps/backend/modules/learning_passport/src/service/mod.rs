// Servicios de aplicación para el módulo learning_passport

use anyhow::Result;
use uuid::Uuid;
use chrono::Utc;
use ed25519_dalek::{SigningKey, VerifyingKey, Signature, Signer, Verifier};
use serde_json;

use crate::repository::LearningPassportRepository;
use crate::domain::{
    LearningInteraction, LifeLearningPassport, LearningPassportId, 
    LearningInteractionId, LearningPassportEvent, PassportStatistics
};

pub struct LearningPassportService {
    repository: LearningPassportRepository,
}

impl LearningPassportService {
    pub fn new(repository: LearningPassportRepository) -> Self {
        Self { repository }
    }
    
    /// Crear un nuevo pasaporte de aprendizaje para un usuario
    pub async fn create_passport(&self, user_address: &str, humanity_proof_key: &str) -> Result<LifeLearningPassport> {
        let passport = LifeLearningPassport {
            id: LearningPassportId::new(),
            user_address: user_address.to_string(),
            humanity_proof_key: humanity_proof_key.to_string(),
            interactions: Vec::new(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
            blockchain_hash: None,
        };
        
        self.repository.create_passport(&passport).await?;
        
        // TODO: Emitir evento de dominio
        // self.emit_event(LearningPassportEvent::PassportCreated { ... }).await?;
        
        Ok(passport)
    }
    
    /// Obtener pasaporte por dirección de usuario
    pub async fn get_passport_by_user(&self, user_address: &str) -> Result<Option<LifeLearningPassport>> {
        self.repository.get_passport_by_user_address(user_address).await
    }
    
    /// Agregar nueva interacción de aprendizaje al pasaporte
    pub async fn add_learning_interaction(
        &self,
        user_address: &str,
        actor: &str,
        verb: &str,
        object: &str,
        result: Option<crate::domain::LearningResult>,
        context: Option<crate::domain::LearningContext>,
    ) -> Result<LearningInteraction> {
        // Obtener o crear pasaporte del usuario
        let mut passport = self.repository.get_passport_by_user_address(user_address).await?;
        
        if passport.is_none() {
            // Crear pasaporte si no existe
            let new_passport = self.create_passport(user_address, "").await?; // TODO: Obtener humanity_proof_key
            passport = Some(new_passport);
        }
        
        let passport = passport.unwrap();
        
        // Crear nueva interacción
        let interaction = LearningInteraction {
            id: LearningInteractionId::new(),
            passport_id: passport.id.clone(),
            actor: actor.to_string(),
            verb: verb.to_string(),
            object: object.to_string(),
            result,
            context,
            timestamp: Utc::now(),
            humanity_proof_key: passport.humanity_proof_key.clone(),
            signature: None, // Se firmará después
            stored_in_blockchain: false,
        };
        
        // Firmar la interacción con la clave de humanidad
        let signed_interaction = self.sign_interaction(&interaction, &passport.humanity_proof_key)?;
        
        // Guardar en base de datos
        self.repository.add_interaction(&signed_interaction).await?;
        
        // TODO: Emitir evento de dominio
        // self.emit_event(LearningPassportEvent::InteractionAdded { ... }).await?;
        
        Ok(signed_interaction)
    }
    
    /// Firmar una interacción de aprendizaje
    fn sign_interaction(&self, interaction: &LearningInteraction, humanity_proof_key: &str) -> Result<LearningInteraction> {
        // Convertir humanity_proof_key a SigningKey
        let key_bytes = hex::decode(humanity_proof_key)?;
        let signing_key = SigningKey::from_bytes(&key_bytes[..32].try_into()?);
        
        // Crear datos para firmar (interacción serializada)
        let interaction_data = serde_json::to_string(&interaction)?;
        let message = interaction_data.as_bytes();
        
        // Firmar la interacción
        let signature = signing_key.sign(message);
        let signature_hex = hex::encode(signature.to_bytes());
        
        // Crear interacción firmada
        let mut signed_interaction = interaction.clone();
        signed_interaction.signature = Some(signature_hex);
        
        Ok(signed_interaction)
    }
    
    /// Verificar firma de una interacción
    pub fn verify_interaction_signature(&self, interaction: &LearningInteraction, humanity_proof_key: &str) -> Result<bool> {
        let key_bytes = hex::decode(humanity_proof_key)?;
        let verifying_key = VerifyingKey::from_bytes(&key_bytes[..32].try_into()?)?;
        
        // Recrear datos de la interacción (sin la firma)
        let mut interaction_without_signature = interaction.clone();
        interaction_without_signature.signature = None;
        let interaction_data = serde_json::to_string(&interaction_without_signature)?;
        let message = interaction_data.as_bytes();
        
        // Verificar firma
        if let Some(signature_hex) = &interaction.signature {
            let signature_bytes = hex::decode(signature_hex)?;
            let signature = Signature::from_bytes(&signature_bytes[..64].try_into()?)?;
            
            Ok(verifying_key.verify(message, &signature).is_ok())
        } else {
            Ok(false)
        }
    }
    
    /// Obtener estadísticas del pasaporte
    pub async fn get_passport_statistics(&self, user_address: &str) -> Result<Option<PassportStatistics>> {
        if let Some(passport) = self.repository.get_passport_by_user_address(user_address).await? {
            Ok(Some(passport.get_statistics()))
        } else {
            Ok(None)
        }
    }
    
    /// Sincronizar interacciones pendientes con blockchain
    pub async fn sync_pending_interactions_with_blockchain(&self) -> Result<()> {
        let pending_interactions = self.repository.get_pending_blockchain_interactions().await?;
        
        for interaction in pending_interactions {
            // TODO: Implementar llamada a gRPC Gateway para almacenar en Keikochain
            // let grpc_client = self.get_grpc_client().await?;
            // grpc_client.store_learning_interaction(interaction.clone()).await?;
            
            // Marcar como almacenada en blockchain
            self.repository.mark_interaction_stored_in_blockchain(&interaction.id).await?;
        }
        
        Ok(())
    }
    
    /// Obtener historial de interacciones de un usuario
    pub async fn get_user_learning_history(&self, user_address: &str) -> Result<Vec<LearningInteraction>> {
        if let Some(passport) = self.repository.get_passport_by_user_address(user_address).await? {
            Ok(passport.get_interactions_chronological().into_iter().cloned().collect())
        } else {
            Ok(Vec::new())
        }
    }
    
    /// Validar interacción de aprendizaje (verificar humanidad y firma)
    pub async fn validate_interaction(&self, interaction: &LearningInteraction) -> Result<bool> {
        // Verificar que la interacción tenga firma
        if interaction.signature.is_none() {
            return Ok(false);
        }
        
        // Verificar firma de la interacción
        let signature_valid = self.verify_interaction_signature(interaction, &interaction.humanity_proof_key)?;
        
        // TODO: Verificar humanidad del usuario (iris, genome, etc.)
        // let humanity_valid = self.verify_humanity(&interaction.humanity_proof_key).await?;
        
        Ok(signature_valid) // && humanity_valid)
    }
    
    /// Generar enlace verificable para compartir pasaporte
    pub async fn generate_shareable_passport_link(&self, user_address: &str) -> Result<String> {
        // TODO: Implementar generación de enlace verificable
        // - Crear token temporal con expiración
        // - Incluir verificación de humanidad
        // - Generar URL que permita verificación pública
        
        Ok(format!("https://keiko-dapp.xyz/verify/passport/{}", user_address))
    }
}
