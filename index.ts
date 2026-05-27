export type AccountStatus = 'pending' | 'active' | 'suspended' | 'disabled'
export type Plan = 'trial' | 'premium'

export interface Profile {
  id: string
  email: string
  full_name: string | null
  avatar_url: string | null
  account_status: AccountStatus
  plan: Plan
  trial_ends_at: string | null
  subscription_ends_at: string | null
  storage_used_bytes: number
  storage_limit_bytes: number
  is_admin: boolean
  created_at: string
  updated_at: string
}

export interface Album {
  id: string
  user_id: string
  name: string
  description: string | null
  cover_photo_id: string | null
  photo_count: number
  is_public: boolean
  created_at: string
  updated_at: string
  cover_photo?: Photo
}

export interface Photo {
  id: string
  user_id: string
  album_id: string | null
  storage_path: string
  thumbnail_path: string | null
  original_name: string
  file_size_bytes: number
  mime_type: string
  width: number | null
  height: number | null
  title: string | null
  description: string | null
  tags: string[]
  taken_at: string | null
  location_name: string | null
  is_favorite: boolean
  created_at: string
  updated_at: string
  url?: string
  thumbnail_url?: string
}

export interface AdminAuditLog {
  id: string
  admin_id: string
  target_user_id: string
  action: 'activate' | 'suspend' | 'disable' | 'reset_storage'
  previous_status: string | null
  new_status: string | null
  notes: string | null
  created_at: string
}

export interface UploadProgress {
  file: File
  progress: number
  status: 'pending' | 'uploading' | 'done' | 'error'
  error?: string
  photoId?: string
}

export interface PaginatedResponse<T> {
  data: T[]
  count: number
  page: number
  pageSize: number
  totalPages: number
}
