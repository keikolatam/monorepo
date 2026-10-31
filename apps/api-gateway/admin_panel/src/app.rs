use leptos::*;
use leptos_meta::*;
use leptos_router::*;

#[component]
pub fn App() -> impl IntoView {
    provide_meta_context();

    view! {
        <Stylesheet id="leptos" href="/pkg/keiko-web-frontend.css"/>
        <Title text="Keiko - Decentralized Learning Platform"/>
        
        <Router>
            <main>
                <Routes>
                    <Route path="" view=HomePage/>
                    <Route path="/passport" view=PassportPage/>
                    <Route path="/tutoring" view=TutoringPage/>
                    <Route path="/marketplace" view=MarketplacePage/>
                    <Route path="/*any" view=NotFound/>
                </Routes>
            </main>
        </Router>
    }
}

#[component]
fn HomePage() -> impl IntoView {
    let (count, set_count) = create_signal(0);
    let on_click = move |_| set_count.update(|count| *count += 1);

    view! {
        <div class="container mx-auto p-4">
            <h1 class="text-4xl font-bold text-center mb-8">
                "Welcome to Keiko"
            </h1>
            <div class="text-center">
                <button 
                    class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
                    on:click=on_click
                >
                    "Click me: " {count}
                </button>
            </div>
        </div>
    }
}

#[component]
fn PassportPage() -> impl IntoView {
    view! {
        <div class="container mx-auto p-4">
            <h1 class="text-3xl font-bold mb-4">"Life Learning Passport"</h1>
            <p>"Your verified learning journey on the blockchain."</p>
        </div>
    }
}

#[component]
fn TutoringPage() -> impl IntoView {
    view! {
        <div class="container mx-auto p-4">
            <h1 class="text-3xl font-bold mb-4">"Tutoring Sessions"</h1>
            <p>"Connect with human and AI tutors."</p>
        </div>
    }
}

#[component]
fn MarketplacePage() -> impl IntoView {
    view! {
        <div class="container mx-auto p-4">
            <h1 class="text-3xl font-bold mb-4">"Safe Learning Spaces"</h1>
            <p>"Discover community-validated learning environments."</p>
        </div>
    }
}

#[component]
fn NotFound() -> impl IntoView {
    #[cfg(feature = "ssr")]
    {
        let resp = expect_context::<leptos_axum::ResponseOptions>();
        resp.set_status(axum::http::StatusCode::NOT_FOUND);
    }

    view! {
        <div class="container mx-auto p-4 text-center">
            <h1 class="text-4xl font-bold text-red-500">"404"</h1>
            <p>"Page not found"</p>
            <a href="/" class="text-blue-500 hover:underline">"Go home"</a>
        </div>
    }
}