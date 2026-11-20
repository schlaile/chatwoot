<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const { t } = useI18n();

// OmniAuth only starts the request phase on a POST carrying the Rails CSRF token.
const csrfToken =
  document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') ||
  '';

const label = computed(
  () => window.chatwootConfig?.oidcLoginLabel || t('LOGIN.OIDC.LABEL')
);
</script>

<template>
  <form method="POST" action="/omniauth/openid_connect">
    <input type="hidden" name="authenticity_token" :value="csrfToken" />
    <button
      type="submit"
      class="inline-flex justify-center w-full px-4 py-3 items-center bg-n-background dark:bg-n-solid-3 rounded-md shadow-sm ring-1 ring-inset ring-n-container dark:ring-n-container focus:outline-offset-0 hover:bg-n-alpha-2 dark:hover:bg-n-alpha-2"
    >
      <Icon icon="i-lucide-key-round" class="size-5 text-n-slate-11" />
      <span class="ml-2 text-base font-medium text-n-slate-12">
        {{ label }}
      </span>
    </button>
  </form>
</template>
