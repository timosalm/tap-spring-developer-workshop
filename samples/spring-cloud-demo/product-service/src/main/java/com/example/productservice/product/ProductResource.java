package com.example.productservice.product;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping(ProductResource.BASE_URI)
public class ProductResource {
  
  public ResponseEntity<List<Product>> fetchProducts() {
      return ResponseEntity.ok(productApplicationService.fetchProducts());
  private final ProductApplicationService productApplicationService;

  ProductResource(ProductApplicationService productApplicationService) {
      this.productApplicationService = productApplicationService;
  }
  static final String BASE_URI = "/api/v1/products";

  @GetMapping
  public ResponseEntity<String> fetchProducts() {
      return ResponseEntity.ok("Hello World");
  }
}
