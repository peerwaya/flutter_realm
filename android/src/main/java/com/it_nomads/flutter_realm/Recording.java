package com.it_nomads.flutter_realm;

import io.realm.RealmObject;
import io.realm.annotations.Index;
import io.realm.annotations.PrimaryKey;

public class Recording extends RealmObject {
    @PrimaryKey
    private String uuid;
    private long createdAt;
    private int videoWidth;
    private int videoHeight;
    @Index
    private String scheduleId;
    @Index
    private String title;
    private double duration;
    private int thumbnailWidth;
    private int thumbnailHeight;
    private byte[] thumbnailData;
    private double frameRate;
    private int fileSize;
    private String digest;
    private String cloudSyncTaskId;
    private String cloudSyncStatus;
    private String cloudStorageProvider;
    private String cloudStorageProviderId;
    private String path;
    private String mimeType;

    public String getUuid() {
        return uuid;
    }

    public void setUuid(String uuid) {
        this.uuid = uuid;
    }

    public long getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(long createdAt) {
        this.createdAt = createdAt;
    }

    public int getVideoWidth() {
        return videoWidth;
    }

    public void setVideoWidth(int videoWidth) {
        this.videoWidth = videoWidth;
    }

    public int getVideoHeight() {
        return videoHeight;
    }

    public void setVideoHeight(int videoHeight) {
        this.videoHeight = videoHeight;
    }

    public String getScheduleId() {
        return scheduleId;
    }

    public void setScheduleId(String scheduleId) {
        this.scheduleId = scheduleId;
    }

    public double getDuration() {
        return duration;
    }

    public void setDuration(double duration) {
        this.duration = duration;
    }

    public int getThumbnailWidth() {
        return thumbnailWidth;
    }

    public void setThumbnailWidth(int thumbnailWidth) {
        this.thumbnailWidth = thumbnailWidth;
    }

    public int getThumbnailHeight() {
        return thumbnailHeight;
    }

    public void setThumbnailHeight(int thumbnailHeight) {
        this.thumbnailHeight = thumbnailHeight;
    }

    public byte[] getThumbnailData() {
        return thumbnailData;
    }

    public void setThumbnailData(byte[] thumbnailData) {
        this.thumbnailData = thumbnailData;
    }

    public double getFrameRate() {
        return frameRate;
    }

    public void setFrameRate(double frameRate) {
        this.frameRate = frameRate;
    }

    public int getFileSize() {
        return fileSize;
    }

    public void setFileSize(int fileSize) {
        this.fileSize = fileSize;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getCloudSyncTaskId() {
        return cloudSyncTaskId;
    }

    public void setCloudSyncTaskId(String cloudSyncTaskId) {
        this.cloudSyncTaskId = cloudSyncTaskId;
    }

    public String getCloudSyncStatus() {
        return cloudSyncStatus;
    }

    public void setCloudSyncStatus(String cloudSyncStatus) {
        this.cloudSyncStatus = cloudSyncStatus;
    }

    public String getCloudStorageProvider() {
        return cloudStorageProvider;
    }

    public void setCloudStorageProvider(String cloudStorageProvider) {
        this.cloudStorageProvider = cloudStorageProvider;
    }

    public String getCloudStorageProviderId() {
        return cloudStorageProviderId;
    }

    public void setCloudStorageProviderId(String cloudStorageProviderId) {
        this.cloudStorageProviderId = cloudStorageProviderId;
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public String getMimeType() {
        return mimeType;
    }

    public void setMimeType(String mimeType) {
        this.mimeType = mimeType;
    }

    public String getDigest() {
        return digest;
    }

    public void setDigest(String digest) {
        this.digest = digest;
    }
}
