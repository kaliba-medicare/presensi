// Face Recognition API Examples

const BASE_URL = 'http://127.0.0.1:8000';

// 1. Register a face embedding
async function registerFace(token, embedding) {
    try {
        const response = await fetch(`${BASE_URL}/api/face/register`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                embedding: embedding // Array of floats representing face embedding
            })
        });

        const data = await response.json();
        console.log('Face registration result:', data);
        return data;
    } catch (error) {
        console.error('Face registration error:', error);
    }
}

// 2. Verify a face embedding
async function verifyFace(token, embedding, photoBase64 = null, location = null) {
    try {
        const body = {
            embedding: embedding // Array of floats representing face embedding
        };
        
        // Optional: include photo and location
        if (photoBase64) body.photo_base64 = photoBase64;
        if (location) body.location = location;

        const response = await fetch(`${BASE_URL}/api/face/verify`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body)
        });

        const data = await response.json();
        console.log('Face verification result:', data);
        return data;
    } catch (error) {
        console.error('Face verification error:', error);
    }
}

// Example usage:
// Assuming you have a user token from authentication

// Example face embedding (in practice, this would come from a face recognition library)
const exampleEmbedding = [
    0.123, 0.456, 0.789, 0.321, 0.654, 0.987, 0.111, 0.222,
    0.333, 0.444, 0.555, 0.666, 0.777, 0.888, 0.999, 0.000
];

// Register a face
// registerFace('YOUR_AUTH_TOKEN', exampleEmbedding);

// Verify a face
// verifyFace('YOUR_AUTH_TOKEN', exampleEmbedding);