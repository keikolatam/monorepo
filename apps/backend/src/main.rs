use anyhow::Result;
use tokio::signal;

#[tokio::main]
async fn main() -> Result<()> {
    // Inicializar logging
    tracing_subscriber::init();
    
    tracing::info!("🎓 Iniciando Keiko Backend - Aplicación Monolítica Modular");
    
    // Inicializar todos los módulos
    identity::init().await?;
    learning_passport::init().await?;
    reputation::init().await?;
    governance::init().await?;
    marketplace::init().await?;
    selfstudy_guides::init().await?;
    
    tracing::info!("✅ Todos los módulos inicializados correctamente");
    
    // Configurar shutdown graceful
    let shutdown = async {
        signal::ctrl_c()
            .await
            .expect("Failed to install CTRL+C signal handler");
        tracing::info!("🛑 Señal de shutdown recibida");
    };
    
    // TODO: Iniciar servidor HTTP y gRPC
    // let server = start_http_server();
    // let grpc_server = start_grpc_server();
    
    // Esperar shutdown
    shutdown.await;
    
    // Cerrar módulos
    tracing::info!("🔄 Cerrando módulos...");
    identity::shutdown().await?;
    learning_passport::shutdown().await?;
    reputation::shutdown().await?;
    governance::shutdown().await?;
    marketplace::shutdown().await?;
    selfstudy_guides::shutdown().await?;
    
    tracing::info!("👋 Keiko Backend cerrado correctamente");
    Ok(())
}
