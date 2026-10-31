use juniper::{EmptySubscription, FieldResult, GraphQLObject, RootNode, graphql_object};
use crate::context::Context;

// GraphQL Types
#[derive(GraphQLObject)]
pub struct User {
    pub id: String,
    pub name: String,
    pub passport_id: Option<String>,
}

#[derive(GraphQLObject)]
pub struct LearningInteraction {
    pub id: String,
    pub user_id: String,
    pub activity_type: String,
    pub content: String,
    pub timestamp: String,
}

#[derive(GraphQLObject)]
pub struct TutoringSession {
    pub id: String,
    pub tutor_id: String,
    pub student_id: String,
    pub subject: String,
    pub status: String,
}

// Query Root
pub struct Query;

#[graphql_object]
#[graphql(context = Context)]
impl Query {
    /// Get user by ID
    async fn user(context: &Context, id: String) -> FieldResult<Option<User>> {
        context.get_user(&id).await
    }

    /// Get learning interactions for a user
    async fn learning_interactions(
        context: &Context, 
        user_id: String
    ) -> FieldResult<Vec<LearningInteraction>> {
        context.get_learning_interactions(&user_id).await
    }

    /// Get active tutoring sessions
    async fn tutoring_sessions(
        context: &Context,
        user_id: String
    ) -> FieldResult<Vec<TutoringSession>> {
        context.get_tutoring_sessions(&user_id).await
    }
}

// Mutation Root
pub struct Mutation;

#[graphql_object]
#[graphql(context = Context)]
impl Mutation {
    /// Create a new learning interaction
    async fn create_learning_interaction(
        context: &Context,
        user_id: String,
        activity_type: String,
        content: String,
    ) -> FieldResult<LearningInteraction> {
        context.create_learning_interaction(user_id, activity_type, content).await
    }

    /// Start a tutoring session
    async fn start_tutoring_session(
        context: &Context,
        tutor_id: String,
        student_id: String,
        subject: String,
    ) -> FieldResult<TutoringSession> {
        context.start_tutoring_session(tutor_id, student_id, subject).await
    }
}

// Schema Definition
pub type Schema = RootNode<'static, Query, Mutation, EmptySubscription<Context>>;

pub fn create_schema() -> Schema {
    Schema::new(Query, Mutation, EmptySubscription::new())
}