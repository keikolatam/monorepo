pub mod app;

use app::*;
use axum::{
    body::Body,
    extract::{Request, State},
    response::{IntoResponse, Response},
    routing::{get, post},
    Router,
};
use leptos::*;
use leptos_axum::{generate_route_list, handle_server_fns, LeptosRoutes};
use tower_http::{cors::CorsLayer, services::ServeDir};
use tower::util::ServiceExt; // for .oneshot
use keiko_graphql_server::schema::create_schema;

#[cfg(feature = "ssr")]
#[tokio::main]
async fn main() {
    let conf = get_configuration(None).await.unwrap();
    let leptos_options = conf.leptos_options;
    let addr = leptos_options.site_addr;
    let routes = generate_route_list(App);

    // GraphQL Schema Integration
    let _graphql_schema = create_schema();

    let app = Router::new()
        // GraphQL endpoint
        .route("/graphql", post(graphql_handler))
        .route("/graphiql", get(graphiql_handler))
        // Server functions
        .route("/api/*fn_name", post(server_fn_handler))
        // Leptos routes
        .leptos_routes(&leptos_options, routes, App)
        // Static files
        .fallback(file_and_error_handler)
        // CORS for development
        .layer(CorsLayer::permissive())
        .with_state(leptos_options);

    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    println!("Listening on http://{}", &addr);
    axum::serve(listener, app.into_make_service())
        .await
        .unwrap();
}

#[cfg(feature = "ssr")]
async fn server_fn_handler(
    State(_leptos_options): State<LeptosOptions>,
    _request: Request<Body>,
) -> impl IntoResponse {
    handle_server_fns(_request).await
}

#[cfg(feature = "ssr")]
async fn graphql_handler(
    State(_leptos_options): State<LeptosOptions>,
    _request: Request<Body>,
) -> impl IntoResponse {
    // GraphQL request handling
    // This would integrate with Juniper's request handling
    "GraphQL endpoint - TODO: implement Juniper integration"
}

#[cfg(feature = "ssr")]
async fn graphiql_handler() -> impl IntoResponse {
    axum::response::Html(juniper::http::graphiql::graphiql_source("/graphql", None))
}

#[cfg(feature = "ssr")]
async fn file_and_error_handler(
    uri: axum::http::Uri,
    State(options): State<LeptosOptions>,
    req: Request<Body>,
) -> Response {
    let root = options.site_root.clone();
    let res = get_static_file(uri.clone(), &root).await.unwrap();

    if res.status() == axum::http::StatusCode::OK {
        res.into_response()
    } else {
        let handler = leptos_axum::render_app_to_stream(
            options.to_owned(),
            move || view! { <App/> },
        );
        handler(req).await.into_response()
    }
}

#[cfg(feature = "ssr")]
async fn get_static_file(
    uri: axum::http::Uri,
    root: &str,
) -> Result<Response<Body>, (axum::http::StatusCode, String)> {
    let req = Request::builder().uri(uri.clone()).body(Body::empty()).unwrap();
    match ServeDir::new(root).oneshot(req).await {
        Ok(res) => Ok(res.into_response()),
        Err(err) => Err((
            axum::http::StatusCode::INTERNAL_SERVER_ERROR,
            format!("Something went wrong: {err}"),
        )),
    }
}

// Client-side hydration
#[cfg(feature = "hydrate")]
#[wasm_bindgen::prelude::wasm_bindgen]
pub fn hydrate() {
    console_error_panic_hook::set_once();
    leptos::mount_to_body(App);
}