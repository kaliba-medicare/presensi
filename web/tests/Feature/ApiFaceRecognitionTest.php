<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\FaceEmbedding;

class ApiFaceRecognitionTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test face registration for a user
     *
     * @return void
     */
    public function test_user_can_register_face_embedding()
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth-token')->plainTextToken;

        $embedding = [0.1, 0.2, 0.3, 0.4, 0.5];

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
                         ->postJson('/api/face/register', [
                             'embedding' => $embedding,
                         ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'message' => 'Face registered'
                 ]);

        // Assert that the face embedding was saved
        $this->assertDatabaseHas('face_embeddings', [
            'user_id' => $user->id
        ]);
    }

    /**
     * Test face verification for a user
     *
     * @return void
     */
    public function test_user_can_verify_face_embedding()
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth-token')->plainTextToken;

        // First register a face embedding
        $embedding = [0.1, 0.2, 0.3, 0.4, 0.5];
        
        $this->withHeader('Authorization', 'Bearer ' . $token)
             ->postJson('/api/face/register', [
                 'embedding' => $embedding,
             ]);

        // Now verify the face with a similar embedding
        $similarEmbedding = [0.11, 0.22, 0.31, 0.42, 0.49]; // Similar to original
        
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
                         ->postJson('/api/face/verify', [
                             'embedding' => $similarEmbedding,
                         ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'message' => 'Attendance recorded'
                 ])
                 ->assertJsonStructure([
                     'message',
                     'similarity'
                 ]);
    }

    /**
     * Test face verification fails when user has no registered face
     *
     * @return void
     */
    public function test_face_verification_fails_when_no_face_registered()
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth-token')->plainTextToken;

        // Try to verify face without registering one
        $embedding = [0.1, 0.2, 0.3, 0.4, 0.5];
        
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
                         ->postJson('/api/face/verify', [
                             'embedding' => $embedding,
                         ]);

        $response->assertStatus(404)
                 ->assertJson([
                     'error' => 'No face enrolled'
                 ]);
    }

    /**
     * Test face registration validation
     *
     * @return void
     */
    public function test_face_registration_requires_embedding()
    {
        $user = User::factory()->create();
        $token = $user->createToken('auth-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
                         ->postJson('/api/face/register', []);

        $response->assertStatus(422);
    }
}