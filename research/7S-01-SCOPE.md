# 7S-01-SCOPE: simple_sql

**BACKWASH** | Date: 2026-01-23

## Problem Domain

Simple_sql provides a high-level SQLite database interface for Eiffel applications. It wraps the low-level SQLite C API through inline C externals, providing:

- Database connection management
- Query execution (SELECT, INSERT, UPDATE, DELETE)
- Prepared statements with parameter binding
- Query builders for fluent SQL construction
- Repository pattern for entity persistence
- Database migrations for schema versioning
- Backup and restore functionality
- Full-text search (FTS5) support
- JSON extension support
- Pagination and cursor-based iteration

## Target Users

- Eiffel developers needing embedded database functionality
- Applications requiring local data persistence without server setup
- Projects using the Simple Eiffel ecosystem

## Business Value

- Eliminates need for external database servers
- Type-safe database access through Eiffel contracts
- Reduces SQL injection risk via prepared statements
- Simplifies migration management for schema evolution

## Out of Scope

- Multi-database connections (PostgreSQL, MySQL)
- Network database protocols
- ORM-style object-relational mapping beyond basic repository pattern
- Database replication or clustering
