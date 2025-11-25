// Face Recognition API Authentication Examples

const BASE_URL = 'http://127.0.0.1:8000';

// 1. Register a new user
async function registerUser() {
    try {
        const response = await fetch(`${BASE_URL}/api/register`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                name: 'John Doe',
                email: 'john@example.com',
                password: 'password123',
                password_confirmation: 'password123'
            })
        });

        const data = await response.json();
        console.log('Register Response:', data);
        return data.data.token;
    } catch (error) {
        console.error('Registration Error:', error);
    }
}

// 2. Login
async function loginUser() {
    try {
        const response = await fetch(`${BASE_URL}/api/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                email: 'john@example.com',
                password: 'password123'
            })
        });

        const data = await response.json();
        console.log('Login Response:', data);
        return data.data.token;
    } catch (error) {
        console.error('Login Error:', error);
    }
}

// 3. Get authenticated user
async function getAuthUser(token) {
    try {
        const response = await fetch(`${BASE_URL}/api/user`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json',
            }
        });

        const data = await response.json();
        console.log('User Data:', data);
        return data;
    } catch (error) {
        console.error('Get User Error:', error);
    }
}

// 4. Logout
async function logoutUser(token) {
    try {
        const response = await fetch(`${BASE_URL}/api/logout`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json',
            }
        });

        const data = await response.json();
        console.log('Logout Response:', data);
        return data;
    } catch (error) {
        console.error('Logout Error:', error);
    }
}

// Example usage:
// Uncomment the following lines to test the functions

// registerUser().then(token => {
//     console.log('Registration successful, token:', token);
// });

// loginUser().then(token => {
//     console.log('Login successful, token:', token);
//     // Use the token for subsequent requests
//     getAuthUser(token).then(userData => {
//         console.log('User data retrieved:', userData);
//         // Logout when done
//         logoutUser(token).then(logoutData => {
//             console.log('Logout successful:', logoutData);
//         });
//     });
// });