package com.example.ARTIFACT_NAME;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping(HelloWorldResource.BASE_URI)
public class HelloWorldResource {
  
  static final String BASE_URI = "/api/v1/helloworld";

  @GetMapping
  public ResponseEntity<String> helloWorld() {
      return ResponseEntity.ok("Hello World");
  }
}
