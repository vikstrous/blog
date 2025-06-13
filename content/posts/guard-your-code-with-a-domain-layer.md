---
title: "Guard your code with a domain layer"
date: 2025-06-13T00:00:00Z
draft: false
---

Numerous architectural models (Clean Architecture, Hexagonal, Onion, Domain‑Driven Design) present different terminology and slightly different structure, yet they converge on a single principle:

> **Place business rules in their own layer.**

This inner layer is variously called *entities*, *core*, *domain model*, or *business‑logic layer*. I will refer to it as the **domain layer**.

Without it, engineers must guess which mutations are legal and every feature starts with code‑base archaeology.

## A fictionalized crypto example

*The scenario below is distilled from common industry issues; the company, schema, and code are illustrative.*

A digital‑asset custody platform pre‑provisions blockchain keys. Because generating a key pair and deriving an address can take more than a minute, a background process maintains a pool of keys ready to use. The intended wallet‑creation workflow is:

1. Reserve a fresh key from the pool.
2. Mark the key as `used`.
3. Commit the wallet and key in a single transaction.

In practice, several Go services accessed the same tables through thin DAO helpers. Some omitted the `used` flag, others toggled it later. Over time:

* Individual keys appeared in multiple wallets.
* The uniqueness invariant could not be articulated without extensive code searches.

Centralizing the invariant in a domain layer resolved the issue and simplified subsequent development.

## Responsibilities of the domain layer

The domain layer contains pure code that enforces invariants. It should not import `net/http`, ORMs, or message‑bus clients. It answers questions such as:

* Is this key available?
* May a wallet transition from `archived` to `active`?
* For which blockchains is a key valid?

All outer layers, such as HTTP handlers, schedulers, CLI tools, must invoke the domain layer rather than manipulating state directly.

More definitions:

* **Application layer** (*service layer*): coordinates transport concerns (HTTP, gRPC) and invokes domain operations.
* **Storage layer** (*repository / DAL*): persists domain objects; it knows SQL, whereas the domain layer does not.

## Code example

```go
package domain

import (
    "context"
    "errors"

    "github.com/google/uuid"
)

// Key represents a pre-provisioned private key.
type Key struct {
    ID         uuid.UUID
    Address    string
    Blockchain string
    Used       bool
}

// Wallet represents a user wallet.
type Wallet struct {
    ID             uuid.UUID
    name           string
    DepositKeyID   uuid.UUID
    DepositAddress string
}

// GetName returns the wallet's name.
func (w *Wallet) GetName() string {
    return w.name
}

// newWallet constructs a Wallet while enforcing invariants.
func newWallet(name string, key Key) (*Wallet, error) {
    if len(name) > 50 {
        return nil, errors.New("wallet name too long (max 50)")
    }
    if key.Used {
        return nil, errors.New("key already in use")
    }
    return &Wallet{
        ID:             uuid.New(),
        name:           name,
        DepositKeyID:   key.ID,
        DepositAddress: key.Address,
    }, nil
}

// KeyPool abstracts key management persistence.
type KeyPool interface {
    Reserve(ctx context.Context) (Key, error)
    MarkUsed(ctx context.Context, id uuid.UUID) error
}

// WalletRepo abstracts wallet persistence.
type WalletRepo interface {
    Store(ctx context.Context, *Wallet) error
    Find(ctx context.Context, id uuid.UUID) (*Wallet, error)
}

// UnitOfWork guarantees atomic execution across repositories.
type UnitOfWork interface {
    Do(ctx context.Context, fn func(ctx context.Context) error) error
}

// WalletCore exposes safe operations for wallets.
type WalletCore struct {
    Keys KeyPool
    Repo WalletRepo
    UoW  UnitOfWork
}

// CreateWallet is the canonical, transactional path for wallet creation.
func (c *WalletCore) CreateWallet(ctx context.Context, name string) (*Wallet, error) {
    var wallet *Wallet
    err := c.UoW.Do(ctx, func(txCtx context.Context) error {
        key, err := c.Keys.Reserve(txCtx)
        if err != nil {
            return err
        }

        wallet, err = newWallet(name, key)
        if err != nil {
            return err
        }

        if err := c.Repo.Store(txCtx, wallet); err != nil {
            return err
        }

        if err := c.Keys.MarkUsed(txCtx, key.ID); err != nil {
            return err
        }

        return nil
    })
    return wallet, err
}
```

Any code outside the domain layer can now rely on three guarantees:

1. Wallet names are at most 50 characters.
2. Each key is used exactly once.
3. Wallet creation reserves and marks a key in one atomic operation.

---

## Retrofitting a domain layer

1. **Select one core concept,** for example, Key or Wallet, not a database table.
2. **Define a constructor and methods** that cover every legal mutation.
3. **Hide struct fields** so external code cannot bypass rules.
4. **Add unit tests** that assert illegal transitions fail.
5. **Extract persistence** into repositories; keep domain structs unaware of SQL, ORMs, etc.
6. Replace direct table updates with domain calls incrementally, feature by feature.

---

## Conclusion

A well‑defined domain layer is not boilerplate. It is the mechanism that preserves invariants as the system and its team grow. Centralize rules early. Each new feature will be easier to add instead of increasing complexity exponentially.
