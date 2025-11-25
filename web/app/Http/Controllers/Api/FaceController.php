<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\FaceEmbedding;
use App\Models\Attendance;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class FaceController extends Controller
{

    public function registerFace(Request $r)
    {
        $r->validate(['embedding'=>'required|array']);
        $user = $r->user();
        $embeddingJson = json_encode($r->embedding);
        $photoPath = null;
        if ($r->has('photo_base64')) {
            $img = $r->photo_base64; // data:image/jpeg;base64,...
            if (preg_match('/^data:image\/(\w+);base64,/', $img, $type)) {
                $img = substr($img, strpos($img, ',') + 1);
                $img = base64_decode($img);
                $ext = $type[1];
                $filename = 'faces-register/' . now()->format('Ymd') . '/' . Str::uuid() . '.' . $ext;
                Storage::disk('public')->put($filename, $img);
                $photoPath = $filename;
            }
        }

        // encrypt embedding before save
        $encrypted = Crypt::encryptString($embeddingJson);

        FaceEmbedding::updateOrCreate(
            ['user_id' => $user->id],
            ['embedding' => $encrypted],
            ['photo_path' => $photoPath]
        );

        return response()->json(['message'=>'Face registered']);
    }

    // public function registerFace(Request $r)
    // {
    //     $r->validate([
    //         'embedding' => 'required|array',
    //         'photo' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
    //     ]);
    //     $user = $r->user();
    //     $embeddingJson = json_encode($r->embedding);
    //     $photoPath = $r->file('photo')->store('registerface/' . now()->format('Ymd'));

    //     // Encrypt embedding
    //     $encrypted = Crypt::encryptString($embeddingJson);

    //     // Simpan data
    //     FaceEmbedding::updateOrCreate(
    //         ['user_id' => $user->id],
    //         [
    //             'embedding' => $encrypted,
    //             'photo'     => $photoPath,
    //         ]
    //     );

    //     return response()->json([
    //         'success' => true,
    //         'message' => 'Face registered successfully',
    //     ]);
    // }


    // Verify face: expects embedding array and optional base64 photo and location
    public function verifyFace(Request $r)
    {
        $r->validate(['embedding' => 'required|array']);
        $user = $r->user();

        $stored = FaceEmbedding::where('user_id', $user->id)->first();
        if (!$stored) {
            return response()->json(['error' => 'No face enrolled'], 404);
        }

        // decrypt stored embedding
        try {
            $storedEmbedding = json_decode(Crypt::decryptString($stored->embedding), true);
            // Pastikan embedding disimpan sebagai array float
            $storedEmbedding = array_map('floatval', $storedEmbedding);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Unable to decrypt embedding'], 500);
        }

        $embedding = $r->embedding; // array floats, tapi mungkin string dari JSON
        $embedding = array_map('floatval', $embedding); // Konversi ke float

        // Normalisasi embedding sebelum perhitungan similarity (opsional, tapi disarankan untuk akurasi)
        $storedEmbedding = $this->normalizeVector($storedEmbedding);
        $embedding = $this->normalizeVector($embedding);

        $similarity = $this->cosineSimilarity($embedding, $storedEmbedding);

        $verified = $similarity >= 0.7; // Turunkan threshold ke 0.5; sesuaikan berdasarkan testing

        // save photo if provided (base64)
        $photoPath = null;
        if ($r->has('photo_base64')) {
            $img = $r->photo_base64; // data:image/jpeg;base64,...
            if (preg_match('/^data:image\/(\w+);base64,/', $img, $type)) {
                $img = substr($img, strpos($img, ',') + 1);
                $img = base64_decode($img);
                $ext = $type[1];
                $filename = 'faces/' . now()->format('Ymd') . '/' . Str::uuid() . '.' . $ext;
                Storage::disk('public')->put($filename, $img);
                $photoPath = $filename;
            }
        }

        Attendance::create([
            'user_id' => $user->id,
            'verified' => $verified,
            'similarity' => $similarity,
            'photo_path' => $photoPath,
            'location' => $r->input('location'),
        ]);

        if ($verified) {
            return response()->json(['message' => 'Attendance recorded', 'similarity' => $similarity]);
        } else {
            return response()->json(['error' => 'Face not matched', 'similarity' => $similarity], 422);
        }
    }

    // Normalisasi vektor (L2 normalization)
    private function normalizeVector(array $vec)
    {
        $norm = sqrt(array_sum(array_map(fn($x) => $x * $x, $vec)));
        if ($norm == 0) return $vec;
        return array_map(fn($x) => $x / $norm, $vec);
    }

    // Performs cosine similarity between two arrays (sudah dinormalisasi)
    private function cosineSimilarity(array $a, array $b)
    {
        $dot = 0.0;
        $n = min(count($a), count($b));
        for ($i = 0; $i < $n; $i++) {
            $dot += $a[$i] * $b[$i];
        }
        return $dot; // Karena sudah dinormalisasi, similarity = dot product
    }
}
