export const environment = {
  production: true,
  baseHref: '/frontend/',
  authConfig: {
    issuer: 'ISSUER_SCHEME://ISSUER_HOST',
    clientId: 'CLIENT_ID_VALUE'
  },
  endpoints: {
    orders: window.location.origin + '/services/order-service/api/v1/orders',
    products: window.location.origin +  '/services/product-service/api/v1/products'
  }
};
