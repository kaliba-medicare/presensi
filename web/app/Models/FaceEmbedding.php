<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FaceEmbedding extends Model
{
    use HasFactory;
    
    protected $fillable = [
        'user_id',
        'embedding',
        'photo_path',
    ];
    
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
