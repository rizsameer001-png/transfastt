import { useState, useRef } from 'react';
import { useAuth } from '../../context/AuthContext';
import { userAPI } from '../../utils/api';
import API from '../../utils/api';
import toast from 'react-hot-toast';
import { User, Lock, Camera, Trash2, Upload, X, FileText, Check } from 'lucide-react';

// ── Single KYC doc replace box ─────────────────────────────────────────────
function DocReplaceBox({ label, fieldName, existing, onUploaded }) {
  const inputRef   = useRef(null);
  const [file, setFile]       = useState(null);
  const [preview, setPreview] = useState(null);
  const [uploading, setUploading] = useState(false);

  const pick = (e) => {
    const f = e.target.files[0];
    if (!f) return;
    if (f.size > 5 * 1024 * 1024) { toast.error('Max 5 MB'); return; }
    setFile(f);
    if (f.type.startsWith('image/')) setPreview(URL.createObjectURL(f));
    e.target.value = '';
  };

  const upload = async () => {
    if (!file) return;
    setUploading(true);
    try {
      const fd = new FormData();
      fd.append('document', file);
      fd.append('field', fieldName);
      const res = await userAPI.uploadKycDoc(fd);
      toast.success(`${label} updated!`);
      onUploaded(fieldName, res.data.document);
      setFile(null); setPreview(null);
    } catch (err) {
      toast.error(err.response?.data?.message || 'Upload failed');
    }
    setUploading(false);
  };

  const url    = existing?.url;
  const isPDF  = url?.includes('/raw/') || url?.endsWith('.pdf');

  return (
    <div className="border border-gray-100 rounded-xl overflow-hidden">
      {/* Current doc */}
      <div className="h-24 bg-gray-50 relative">
        {file ? (
          preview
            ? <img src={preview} alt={label} className="w-full h-full object-cover" />
            : <div className="w-full h-full flex items-center justify-center gap-2">
                <FileText size={22} className="text-red-400" />
                <span className="text-xs text-gray-500 truncate px-2">{file.name}</span>
              </div>
        ) : url ? (
          isPDF
            ? <a href={url} target="_blank" rel="noreferrer"
                className="w-full h-full flex flex-col items-center justify-center gap-1 hover:bg-gray-100 transition-colors">
                <FileText size={22} className="text-red-400" />
                <span className="text-xs text-gray-400">View PDF</span>
              </a>
            : <img src={url} alt={label} className="w-full h-full object-cover" />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <span className="text-xs text-gray-300">Not uploaded</span>
          </div>
        )}

        {/* Status chip */}
        <div className={`absolute top-1.5 left-1.5 text-xs px-2 py-0.5 rounded-full font-semibold
          ${url ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-400'}`}>
          {url ? <><Check size={10} className="inline mr-0.5" />Uploaded</> : 'Missing'}
        </div>

        {/* Clear new pick */}
        {file && (
          <button onClick={() => { setFile(null); setPreview(null); }}
            className="absolute top-1.5 right-1.5 w-6 h-6 rounded-full bg-black/60
                       flex items-center justify-center hover:bg-red-600">
            <X size={12} className="text-white" />
          </button>
        )}
      </div>

      {/* Label + actions */}
      <div className="px-3 py-2 bg-white border-t border-gray-100">
        <p className="text-xs font-semibold text-gray-600 mb-1.5">{label}</p>
        <input ref={inputRef} type="file" accept="image/jpeg,image/png,application/pdf"
          className="hidden" onChange={pick} />
        <div className="flex gap-1.5">
          <button onClick={() => inputRef.current.click()}
            className="flex-1 text-xs bg-gray-100 hover:bg-gray-200 rounded-lg py-1.5 font-medium
                       flex items-center justify-center gap-1 transition-colors">
            <Upload size={11} /> {file ? 'Change' : 'Pick'}
          </button>
          {file && (
            <button onClick={upload} disabled={uploading}
              className="flex-1 text-xs bg-primary-600 hover:bg-primary-700 text-white rounded-lg
                         py-1.5 font-medium flex items-center justify-center gap-1 transition-colors disabled:opacity-60">
              {uploading
                ? <div className="w-3 h-3 border border-white border-t-transparent rounded-full animate-spin" />
                : <Check size={11} />}
              {uploading ? 'Saving…' : 'Save'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Main Profile Page ──────────────────────────────────────────────────────
export default function ProfilePage() {
  const { user, updateUser } = useAuth();
  const avatarRef = useRef(null);
  const [form, setForm]     = useState({
    firstName: user?.firstName || '',
    lastName:  user?.lastName  || '',
    phone:     user?.phone     || '',
  });
  const [saving, setSaving]       = useState(false);
  const [pwdForm, setPwdForm]     = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [savingPwd, setSavingPwd] = useState(false);
  const [uploadingAvatar, setUploadingAvatar] = useState(false);
  const [kycDocs, setKycDocs]     = useState(null); // loaded lazily
  const [loadingDocs, setLoadingDocs] = useState(false);
  const [docsLoaded, setDocsLoaded]   = useState(false);

  // Avatar
  const handleAvatarPick = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) { toast.error('Avatar must be under 2 MB'); return; }
    setUploadingAvatar(true);
    try {
      const fd = new FormData();
      fd.append('avatar', file);
      const res = await userAPI.uploadAvatar(fd);
      updateUser({ ...user, avatar: res.data.avatar });
      toast.success('Profile photo updated!');
    } catch (err) {
      toast.error(err.response?.data?.message || 'Upload failed');
    }
    setUploadingAvatar(false);
    e.target.value = '';
  };

  const handleDeleteAvatar = async () => {
    setUploadingAvatar(true);
    try {
      await userAPI.deleteAvatar();
      updateUser({ ...user, avatar: null });
      toast.success('Photo removed');
    } catch { toast.error('Failed to remove photo'); }
    setUploadingAvatar(false);
  };

  // Profile form
  const handleProfile = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const res = await API.put('/users/profile', form);
      updateUser(res.data.user);
      toast.success('Profile updated!');
    } catch { toast.error('Update failed'); }
    setSaving(false);
  };

  // Password form
  const handlePassword = async (e) => {
    e.preventDefault();
    if (pwdForm.newPassword !== pwdForm.confirmPassword) {
      toast.error('New passwords do not match'); return;
    }
    setSavingPwd(true);
    try {
      await API.put('/auth/change-password', {
        currentPassword: pwdForm.currentPassword,
        newPassword:     pwdForm.newPassword,
      });
      toast.success('Password changed!');
      setPwdForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
    } catch (err) { toast.error(err.response?.data?.message || 'Failed'); }
    setSavingPwd(false);
  };

  // Load KYC docs on demand
  const loadDocs = async () => {
    if (docsLoaded) return;
    setLoadingDocs(true);
    try {
      const { default: api } = await import('../../utils/api');
      const res = await api.default?.get('/kyc/status') || await (await import('../../utils/api')).kycAPI.getStatus();
      setKycDocs(res.data.kyc);
      setDocsLoaded(true);
    } catch { toast.error('Could not load documents'); }
    setLoadingDocs(false);
  };

  const handleDocUploaded = (field, doc) => {
    setKycDocs(prev => prev ? { ...prev, [field]: doc } : prev);
  };

  const initials = `${user?.firstName?.[0] || ''}${user?.lastName?.[0] || ''}`;

  return (
    <div className="max-w-2xl mx-auto space-y-6 animate-fade-in">
      <h1 className="text-2xl font-bold text-gray-900">Profile Settings</h1>

      {/* ── Avatar + info ── */}
      <div className="card">
        <div className="flex items-center gap-5 mb-6 pb-6 border-b border-gray-100">
          {/* Avatar */}
          <div className="relative flex-shrink-0">
            {user?.avatar
              ? <img src={user.avatar} alt="Avatar"
                  className="w-20 h-20 rounded-full object-cover ring-2 ring-primary-100" />
              : <div className="w-20 h-20 bg-primary-600 rounded-full flex items-center justify-center
                               text-white text-2xl font-bold ring-2 ring-primary-100">
                  {initials}
                </div>
            }
            {/* Camera overlay */}
            <button
              onClick={() => avatarRef.current.click()}
              disabled={uploadingAvatar}
              className="absolute bottom-0 right-0 w-7 h-7 bg-primary-600 rounded-full
                         flex items-center justify-center hover:bg-primary-700 transition-colors
                         shadow-md disabled:opacity-60"
            >
              {uploadingAvatar
                ? <div className="w-3 h-3 border border-white border-t-transparent rounded-full animate-spin" />
                : <Camera size={14} className="text-white" />}
            </button>
            <input ref={avatarRef} type="file" accept="image/jpeg,image/png,image/webp"
              className="hidden" onChange={handleAvatarPick} />
          </div>

          <div className="flex-1 min-w-0">
            <p className="text-xl font-bold text-gray-900">{user?.firstName} {user?.lastName}</p>
            <p className="text-sm text-gray-500 truncate">{user?.email}</p>
            <div className="flex items-center gap-2 mt-1.5 flex-wrap">
              <span className={`badge ${user?.kycStatus === 'approved'
                ? 'bg-green-100 text-green-700'
                : user?.kycStatus === 'submitted' ? 'bg-blue-100 text-blue-700'
                : 'bg-yellow-100 text-yellow-700'}`}>
                KYC: {user?.kycStatus}
              </span>
            </div>
          </div>

          {/* Remove avatar button */}
          {user?.avatar && (
            <button onClick={handleDeleteAvatar} disabled={uploadingAvatar}
              className="p-2 rounded-xl text-gray-400 hover:text-red-500 hover:bg-red-50
                         transition-colors flex-shrink-0" title="Remove photo">
              <Trash2 size={16} />
            </button>
          )}
        </div>

        {/* Personal info form */}
        <form onSubmit={handleProfile} className="space-y-4">
          <h3 className="font-bold text-gray-800 flex items-center gap-2 text-sm">
            <User size={15} /> Personal Information
          </h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">First Name</label>
              <input className="input-field" value={form.firstName}
                onChange={e => setForm(f => ({ ...f, firstName: e.target.value }))} />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-1.5">Last Name</label>
              <input className="input-field" value={form.lastName}
                onChange={e => setForm(f => ({ ...f, lastName: e.target.value }))} />
            </div>
          </div>
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1.5">Phone</label>
            <input className="input-field" value={form.phone}
              onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} />
          </div>
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1.5">Email</label>
            <input className="input-field bg-gray-50 text-gray-400 cursor-not-allowed"
              value={user?.email} disabled />
          </div>
          <button type="submit" disabled={saving} className="btn-primary">
            {saving ? 'Saving...' : 'Save Changes'}
          </button>
        </form>
      </div>

      {/* ── KYC Documents ── */}
      <div className="card">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-bold text-gray-800 flex items-center gap-2 text-sm">
            <FileText size={15} /> KYC Documents
          </h3>
          {!docsLoaded && (
            <button onClick={loadDocs} disabled={loadingDocs}
              className="text-xs text-primary-600 font-semibold hover:underline flex items-center gap-1">
              {loadingDocs
                ? <><div className="w-3 h-3 border border-primary-600 border-t-transparent rounded-full animate-spin" /> Loading…</>
                : 'View & Update'}
            </button>
          )}
        </div>

        {!docsLoaded && !loadingDocs && (
          <p className="text-sm text-gray-400 text-center py-4">
            Click "View & Update" to manage your identity documents
          </p>
        )}

        {loadingDocs && (
          <div className="grid grid-cols-2 gap-3">
            {[1,2,3,4].map(i => <div key={i} className="h-32 bg-gray-50 rounded-xl animate-pulse" />)}
          </div>
        )}

        {docsLoaded && !kycDocs && (
          <p className="text-sm text-gray-400 text-center py-4">
            No KYC submitted yet. Go to <a href="/kyc" className="text-primary-600 underline">KYC page</a> to get started.
          </p>
        )}

        {docsLoaded && kycDocs && (
          <>
            <p className="text-xs text-gray-400 mb-3">
              Click "Pick" on any document to replace it. Changes are saved individually.
            </p>
            <div className="grid grid-cols-2 gap-3">
              {[
                { label: 'ID Front',         field: 'idFrontImage'   },
                { label: 'ID Back',          field: 'idBackImage'    },
                { label: 'Selfie',           field: 'selfieImage'    },
                { label: 'Proof of Address', field: 'proofOfAddress' },
              ].map(({ label, field }) => (
                <DocReplaceBox
                  key={field}
                  label={label}
                  fieldName={field}
                  existing={kycDocs[field]}
                  onUploaded={handleDocUploaded}
                />
              ))}
            </div>
          </>
        )}
      </div>

      {/* ── Change Password ── */}
      <div className="card">
        <form onSubmit={handlePassword} className="space-y-4">
          <h3 className="font-bold text-gray-800 flex items-center gap-2 text-sm">
            <Lock size={15} /> Change Password
          </h3>
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1.5">Current Password</label>
            <input type="password" required className="input-field"
              value={pwdForm.currentPassword}
              onChange={e => setPwdForm(f => ({ ...f, currentPassword: e.target.value }))} />
          </div>
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1.5">New Password</label>
            <input type="password" required minLength={8} className="input-field"
              value={pwdForm.newPassword}
              onChange={e => setPwdForm(f => ({ ...f, newPassword: e.target.value }))} />
          </div>
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1.5">Confirm New Password</label>
            <input type="password" required minLength={8} className="input-field"
              value={pwdForm.confirmPassword}
              onChange={e => setPwdForm(f => ({ ...f, confirmPassword: e.target.value }))} />
          </div>
          <button type="submit" disabled={savingPwd} className="btn-primary">
            {savingPwd ? 'Updating...' : 'Update Password'}
          </button>
        </form>
      </div>
    </div>
  );
}
