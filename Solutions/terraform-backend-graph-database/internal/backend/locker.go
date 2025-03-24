package backend

import "sync"

// Locker 实现锁定和解锁机制
type Locker struct {
    mutex sync.Mutex
    locked bool
}

// Lock 加锁状态
func (l *Locker) Lock() error {
    l.mutex.Lock()
    l.locked = true
    return nil
}

// Unlock 解锁状态
func (l *Locker) Unlock() error {
    l.locked = false
    l.mutex.Unlock()
    return nil
}
