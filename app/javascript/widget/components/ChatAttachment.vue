<template>
  <file-upload :size="4096 * 2048" @input-file="onFileUpload">
    <span class="attachment-button ">
      <i v-if="!isUploading.image" class="ion-android-attach" />
      <spinner v-if="isUploading" size="small" />
    </span>
  </file-upload>
</template>

<script>
import FileUpload from 'vue-upload-component';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: { FileUpload, Spinner },
  props: {
    onAttach: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return { isUploading: false };
  },
  methods: {
    getFileType(fileType) {
      return fileType.includes('image') ? 'image' : 'file';
    },
    async onFileUpload(file) {
      this.isUploading = true;
      try {
        const thumbUrl = window.URL.createObjectURL(file.file);
        await this.onAttach({
          fileType: this.getFileType(file.type),
          file: file.file,
          thumbUrl,
        });
      } catch (error) {
        // Error
      }
      this.isUploading = false;
    },
  },
};
</script>
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.attachment-button {
  background: transparent;
  border: 0;
  cursor: pointer;
  position: relative;
  padding-right: $space-smaller;
  width: 20px;

  i {
    font-size: $font-size-large;
    color: $color-gray;
  }
}
</style>
<style lang="scss">
.file-uploads .attachment-button + label {
  cursor: pointer;
}
</style>
